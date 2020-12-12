```@meta
CurrentModule = Actors
```
# Getting Started with Actors

You may have heard about the Actor Model, but here we present actors as practical things, which you can `spawn`, `send` messages to, `receive` or `request` messages from, `call`, `cast` to them, `query` and `update!` them. Please follow along in your Julia REPL and don't hesitate to try things out.

## Creation: `spawn`

The basic mechanism to *create* a new actor is the [`spawn`](@ref) function. You have to import it explicitly:

```@repl intro
using Actors
import Actors: spawn, newLink
```

You `spawn` an actor with a *behavior*. A behavior is a callable Julia object.

```@repl intro
myactor = spawn(Threads.threadid)
```

`spawn` returned an actor *link*. Now - as we will discover right away - our actor is *responsive* and waits for our *messages*.

## Actor `Link`s

A [`Link`](@ref) is the actor's mail address and its only representation. Over the returned link it is possible to *send* messages to the actor or to use other messaging functions. For example if you `call` or `request` it, you `send` a `Call` message to the actor to execute its behavior and to respond with the result:

```@repl intro
call(myactor)
```

Now what happens if you `send` your actor a message which it cannot understand?

```@repl intro
send(myactor, "Boom")
Actors.info(myactor)
```

We caused our actor to fail. Ouch!

## Behaviors: `become` and `become!`

We want our actor to do something more meaningful! Let's write our own behavior. We want our actor to calculate something and to `send` the result back to a given address:

```@repl intro
function calc(addr::Link, f::Function, args...)
    send(addr, f(args...))
end
```

With `newLink` we create a link for ourselves, `spawn` a new actor with a `calc` behavior and give it that newly created link as *acquaintance* parameter:

```@repl intro
me = newLink()
myactor = spawn(calc, me)
```

We applied our `calc` function partially to `me`. Now our actor holds the `me` link as acquaintance and we need to `send` it only the rest of the parameters to cause it to execute the given function `f` on some parameters and to send the result back:

```@repl intro
send(myactor, +, 1, 2, 3, 4)
receive(me)
```

If we want our actor to do only multiplication, we can change its behavior with [`become!`](@ref) to `calc` with new acquaintances:

```@repl intro
become!(myactor, calc, me, *);
```

The actor's new behavior is `calc` with two acquaintances `me` and `*`, and thus it does multiplication only. As before we `send` it the communication parameters to multiply and `receive` the result:

```@repl intro
send(myactor, 1,2,3,4)
receive(me)
```

An actor can change also its own behavior with [`become`](@ref). Since an actor does what its behavior tells it to do, you use `become` inside a behavior function to cause the actor to switch to a new behavior. Instead `become!` is a call from the outside of an actor. A behavior change is effective for the next message an actor receives.

## Communication: `send` and `receive`

When we used [`send`](@ref) and [`receive`](@ref) in our experiments so far, we did *asynchronous communication* with our actor. After sending something  we could have done other work and then receive the result later.

What happens if we try to `receive` something from a failed actor?

```@repl intro
send(myactor, 5, "x")
receive(me)
```

After some seconds we got a `Timeout()`.

## Actor Protocol: `request`

We don't give up with it and start it again, but now we want an adding machine with an offset of 1000:

```@repl intro
myactor = spawn(+, 1000)
```

Our actor now has no acquaintance of `me`, neither has its behavior any `send` instruction. If we send it something, it will only add that to 1000 but not respond anything.

Here the *actor protocol* comes to our rescue. It allows us to communicate with actors even if their behaviors don't send anything. Actors understand messaging patterns.  For example if we send an actor a [`Call`](@ref), it knows that it must send a [`Response`](@ref) with the result. Let's try that out:

```@repl intro
send(myactor, Actors.Call((1,2,3), me))
receive(me)
ans.y
```

The actor added (1,2,3) to 1000 and sent the result back to the provided link. Then we received it asynchronously.

The [`request`](@ref) function is a wrapper for synchronous bidirectional communication. It will create a link internally and `send` it with the communication parameters as a `Call` (or another given message type) to the actor. That one sends a `Response` back to the received link, and `request` then delivers the response:

```@repl intro
request(myactor, 1,2,3)
```

This is called *synchronous communication* since `request` **blocks** until it `receive`s the result (or a `Timeout()`).

## More Control: `call`, `cast`, `exec`, `query`, `update!` ...

There are more such actor protocols and API functions.

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

With [`exec`](@ref) we can tell an actor to execute any function and to deliver the result:

```@repl intro
exec(myactor, broadcast, cos, pi .* (-2:2))
```

Actors have internal state variables which we normally don't need to work with. We can [`update!`](@ref) those variables. One example for such a use is to `update!` the actor's current acquaintance parameter (1000) to 500. Then it adds to 500:

```@repl intro
update!(myactor, Args(500))
call(myactor, 500)
```

But we could have achieved the same with `become!(myactor, +, 500)`.

Finally we [`exit!`](@ref) the actor since we are finished with this introduction:

```@repl intro
exit!(myactor)
send(myactor, 500)
```

Trying to `send` it something now throws an exception.
