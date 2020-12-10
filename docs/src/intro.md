```@meta
CurrentModule = Actors
```
# Getting Started with Actors

You may have heard about the Actor Model, but here we present actors as a very practical thing, which you can `spawn`, `send` messages to, `receive` or `request` messages from, `call` them, `cast` to them, `query` and `update!` them. Please follow along in your Julia REPL and don't hesitate to try things out.

## `spawn`

The basic mechanism to create new actors is the [`spawn`](@ref) function. You have to import it explicitly:

```@repl intro
using Actors
import Actors: spawn, newLink
```

You then can `spawn` actors with any callable Julia object. This is called a [behavior](behaviors.md) function.

```@repl intro
myactor = spawn(Threads.threadid)
```

`spawn` returned an actor [`Link`](@ref). This is the actor's mail address and its only representation. You can use it to send messages to it or to call it. If you call it, it executes its behavior and responds with the result:

```@repl intro
call(myactor)
```

Now currently our actor does only that: it responds its thread id until you send it a message which it cannot understand or you stop it.

```@repl intro
send(myactor, "Boom")
Actors.info(myactor)
```

We caused our actor to fail. Ouch!

## `become`

Now we want our actor to do something more meaningful. Let's write our own behavior function. We want a calculator actor sending the result of an arithmetic operation back to a given address:

```@repl intro
function calc(addr::Link, f::Function, args...)
    send(addr, f(args...))
end
```

Now we create a link for ourselves and start a new actor with a `calc` behavior and that link as *acquaintance* parameter.

```@repl intro
me = newLink()
myactor = spawn(calc, me)
```

We applied our `calc` function partially to `me`. Now our actor holds the `me` link as acquaintance and we need to `send` it only the rest of the parameters to cause it to do execute `f` on some parameters and to send the result back to `me`:

```@repl intro
send(myactor, +, 1, 2, 3, 4)
receive(me)
```

If we want our actor to do only multiplication, we can change its behavior with [`become!`](@ref) to `calc` with new acquaintances:

```@repl intro
become!(myactor, calc, me, *);
```

Now it does multiplication only and we can `send` it the communication parameters and `receive` the result:

```@repl intro
send(myactor, 1,2,3,4)
receive(me)
```

An actor can change also its own behavior with [`become`](@ref). Since an actor does what its behavior tells it to do, you use `become` inside a behavior function to cause the actor to switch to a new behavior. Instead `become!` is a call from the outside of an actor. A behavior change is effective for the next message an actor receives.

## `send` and `receive`

When we used [`send`](@ref) and [`receive`](@ref) in our experiments so far, we did *asynchronous communication* with our actor. After sending something to it we could have done other work and receive the result later.

But what happens if we try to `receive` something from a failed actor?

```@repl intro
send(myactor, 5, "x")
receive(me)
```

After some seconds we got a `Timeout()`.

## `request`

We don't give up with it and start it again, but now we want our actor to be an adding machine with an offset of 1000:

```@repl intro
myactor = spawn(+, 1000)
```

Now our actor has no acquaintance of `me` neither has its behavior any send instruction. If we `send` it something, it will only add to 1000 but not respond anything.

Now we can use [`request`](@ref). This will create a link internally and `send` it and the communication parameters with a [`Request`](@ref) to the actor. Then it knows that it must send a [`Response`](@ref) to the received link. `request` can then deliver the response:

```@repl intro
request(myactor, 1,2,3)
```

This is *synchronous communication*. `request` blocks until it `receive`s the result (or a `Timeout()`).

## `call`, `cast`, `query`, `update!` ...

Can we still do asynchronous communication with this actor? Yes we can, if we use [`call`](@ref) with the `me` link. This sends the given link to the actor and it responds to it. Then we can `receive` the result asynchronously:

```@repl intro
call(myactor, me, 1000)
receive(me).y
```

If we don't provide a return link to `call`, it will use `request` and deliver the result synchronously:

```@repl intro
call(myactor, 2000)
```

```@repl intro
```

```@repl intro
```

```@repl intro
```

```@repl intro
```

```@repl intro
```
