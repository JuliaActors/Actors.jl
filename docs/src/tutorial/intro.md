# Getting Started with Actors

```@meta
CurrentModule = Actors
```

You need to know only a few quite self-explanatory functions to get started with concurrent actor programming:

| API function | Brief description |
|:-------------|:------------------|
| [`spawn`](@ref) | create an actor with a behavior and get a [`Link`](@ref) to it, |
| [`send`](@ref), [`receive`](@ref) | send and receive messages over an actor `Link`, |
| [`request`](@ref), [`call`](@ref) | request or call something from an actor (behavior), |
| [`cast`](@ref) | cast something to an actor (behavior), |
| [`become`](@ref), [`become!`](@ref) | change the behavior of an actor, |
| [`query`](@ref), [`update!`](@ref) | query or update an actor's state. |

When we introduce those functions, please follow along in your Julia REPL and don't hesitate to try things out.

## Create an actor

The basic mechanism to *create* a new actor is the `spawn` function. You have to import it explicitly:

```@repl intro
using Actors, .Threads
import Actors: spawn, newLink
```

You `spawn` an actor with a *behavior*. A behavior is a callable Julia object (a function, functor …) and some parameters to it. We start our first actor with a parameterless `threadid` behavior, which returns the thread number, where it resides:  

```@repl intro
myactor = spawn(threadid)
```

That returned an actor `Link`. Now - as we will discover right away - our actor is *responsive* and waits for our *messages*.

## Actor `Link`s

A [`Link`](@ref) is the actor's mail address and its only representation. You use it to `send` messages to the actor or to use other messaging functions like [`info`](@ref). If you `call` it, you trigger its behavior and get a result back:

```@repl intro
info(myactor)         # get some info from it
call(myactor)         # call its behavior function
```

Now what happens if you `send` your actor a message which it cannot understand?

```@repl intro
send(myactor, :boom)  # cause the actor to fail
info(myactor)
```

We caused our actor to fail. Ouch!

## Actor behavior

Now let's write our own behavior function! We want our actor to execute a given function `f` on parameters `args...` and to `send` the result back to a given address `addr`:

```@repl intro
calc(addr::Link, f::Function, args...) = send(addr, f(args...))
```

With [`newLink`](@ref) we create a link, where we can receive the actor's answer. We `spawn` a new actor with our `calc` behavior function and give it that newly created link as *acquaintance* parameter:

```@repl intro
me = newLink()
myactor = spawn(calc, me)
```

Now our actor holds the `me` link as acquaintance. Its *behavior* is the `calc` function together with the `me` link.

## `send` and `receive` Messages

We need to `send` it only the rest of the parameters to cause it to execute its behavior and to send the result back. If we send it a `+` and some values, it will add them and send the result to the given `me` link:

```@repl intro
send(myactor, +, 1, 2, 3, 4)
receive(me)
```

Now we did *asynchronous communication* with our actor. After sending it something, we could have done other work and then received the result later.

## Change behavior

If we want our actor to do only multiplication, we can change its behavior with `become!` to `calc` with new acquaintances:

```@repl intro
become!(myactor, calc, me, *);
```

The actor's new behavior is `calc` with two acquaintances `me` and `*`, and thus it does multiplication only. As before we `send` it the communication parameters to multiply and `receive` the result:

```@repl intro
send(myactor, 1,2,3,4)
receive(me)
```

An actor can change also its own behavior with `become` inside its behavior function. Instead `become!` is a call from the outside of an actor. A behavior change is effective for the next message an actor receives.

## A communication failure

What happens if a communication fails? Let's try that out: We cause our actor to fail, so it will not `send` back anything. Then we try to `receive` an answer:

```@repl intro
send(myactor, +, 5, "x")
receive(me)
```

After some seconds we got a `Timeout()`.

## The actor protocol

We don't give up with it and start it again, but now we want it to be an adding machine with an offset of 1000:

```@repl intro
myactor = spawn(+, 1000)
```

Our actor now has no acquaintance of `me`, neither has its behavior any `send` instruction. If we send it something, it will only add that to 1000 but not respond anything. The *message protocol* allows us to communicate with actors even if their behaviors don't send anything. Actors understand messaging patterns.

The [`request`](@ref) function is a wrapper for *synchronous communication*. It will create a link internally and `send` it with the communication parameters as a [`Call`](@ref) (or another given message type) to the actor. That sends a [`Response`](@ref) back to the received link, and `request` then delivers the response:

```@repl intro
request(myactor, 1,2,3)
```

This is *synchronous communication* since `request` **blocks** until it `receive`s the result (or a `Timeout()`).

## `call`, `cast` and `query`

Then there are more [user API](../api/user_api.md) functions.

We can do asynchronous communication with our actor if we use [`call`](@ref) with the `me` link. This sends the given link to the actor and it responds to it. Then we can `receive` the result asynchronously:

```@repl intro
call(myactor, me, 1000)
receive(me).y
```

If we don't provide a return link to `call`, it will use `request` and deliver the result synchronously:

```@repl intro
call(myactor, 2000)
```

Another possibility to communicate asynchronously with an actor is to [`cast`](@ref) it parameters and then to [`query`](@ref) the result afterwards.

```@repl intro
cast(myactor, 3000)
query(myactor, :res)
```

But this will work fine only if between those two calls to `myactor` there is not another actor communicating with it. If for example our actor has mutual variables as acquaintances, we can use `cast` to set parameters or to do anything else where we don't need a response.

## More Control: `exec`, `update!`, `exit!` …

With [`exec`](@ref) we can tell an actor to execute any function and to deliver the result:

```@repl intro
exec(myactor, broadcast, cos, pi .* (-2:2))
```

Actors have internal state variables, which we normally don't need to work with. We can [`update!`](@ref) those variables. Let's `update!` the actor's current acquaintance parameter (1000) to 500. Then it adds to 500:

```@repl intro
update!(myactor, Args(500))
call(myactor, 500)
```

But we could have achieved the same with `become!(myactor, +, 500)`.

Finally we [`exit!`](@ref) our actor since we are finished with this introduction:

```@repl intro
exit!(myactor)
send(myactor, 500)
```

Trying to `send` it something now throws an exception.

## Actor Systems

For this introduction we have worked with one actor. But there is no point in doing that. Actors come in systems. They can assume different and arbitrary behaviors, create other actors and then compose into systems by communicating via messages. Thus they can represent arbitrary concurrent systems.

Let's build a minimal actor system. It consists of two actors, a `greeter` actor for composing a greeting and a `sayhello` actor for communication:

```@repl intro
greet(greeting, msg) = greeting*", "*msg*"!" # a greetings server behavior
hello(greeter, to) = request(greeter, to)    # a greetings client behavior
greeter = spawn(greet, "Hello")              # start the server with a greet string
sayhello = spawn(hello, greeter)             # start the client with a link to the server
request(sayhello, "World")                   # request the client
request(sayhello, "Kermit")
```

We could have done that without actors. But, come on, add a third one, saying hello asynchronously. Then you need a forth one to channel the access of the `hello` actors to the console …
