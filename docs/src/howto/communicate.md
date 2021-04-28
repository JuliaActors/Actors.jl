# How to communicate with actors
```@meta
CurrentModule = Actors
```

An actor dispatches an incoming message 

- as a *communication* parameter to its behavior function or
- if it is a [`Msg`](@ref), it processes it according to the [message protocol](../manual/protocol.md).

Then it immediately proceeds to the next message if there is one or it waits for it.

## by `send`

If we [`send`](@ref) an actor a message (which is not of type `Msg`), we cause it to pass it as a communication argument to its behavior:

```julia
julia> using Actors

julia> import Actors: spawn, newLink

julia> myactor = spawn(println, "Hello ")
Link{Channel{Any}}(Channel{Any}(32), 1, :default)

julia> send(myactor, "World!");
Hello World!
```

Actors can send messages to other actors if they have their links:

```julia
julia> pserv = spawn(println)                    # spawn a print server
Link{Channel{Any}}(Channel{Any}(32), 1, :default)

julia> become!(myactor, send, pserv, "Hello ");  # cause myactor to use it

julia> send(myactor, "Kermit!");
Hello Kermit!
```

Actors receive messages implicitly.

## `receive`

Receiving a message is a blocking operation. Since actors are implemented as Julia `Task`s, either they are busy in processing a message or waiting for the next message to arrive. We can use [`receive`](@ref) explicitly to get messages from actors. To do it, we 

1. use [`newLink`](@ref) to create a Link,
2. communicate it to an actor and
3. cause it to `send` something to the given link.
4. Then we can `receive` the actor's message.

```julia
julia> me = newLink()
Link{Channel{Any}}(Channel{Any}(32), 1, :local)

julia> become!(myactor, (f, args...)->send(me, f(args...)));

julia> send(myactor, +, 1, 2, 3)
(+, 1, 2, 3)

julia> println("now doing something else ...")
now doing something else ...

julia> receive(me)
6
```

This is *asynchronous bidirectional communication* : sender and receiver are decoupled.

- If we call `receive` after the message has been delivered, it will return it immediately.
- If we call it before, it will wait until delivery or until it times out.

```julia
julia> receive(me)
Actors.Timeout()
```

If we want to do *synchronous communication* we combine a `send` and `receive` to an actor into one code block:

```julia
julia> begin
           send(myactor, +, 4, 5, 6)
           receive(me)
       end
15
```

This will block until the actor responds or until the communication times out.

## with the messaging protocol

The [messaging protocol](../manual/protocol.md) is another way to communicate with an actor. It can be used to cause an actor to do also other things e.g. giving information, executing arbitrary functions or updating parameters. Here we demonstrate it briefly with a [`Call`](@ref) - [`Response`](@ref) pattern:

We cause our actor to assume a `+`-behavior. That behavior doesn't send a result back back. But if we send that actor a `Call` message with some arguments in a `Tuple`, it will send the result as a `Response` back to the given link:

```julia
julia> become!(myactor, +);

julia> send(myactor, Actors.Call((1,2,3), me))
Actors.Call((1, 2, 3), Link{Channel{Any}}(Channel{Any}(32), 1, :local))

julia> receive(me)
Response(6, Link{Channel{Any}}(Channel{Any}(32), 1, :default))

julia> ans.y
6
```

A user or programmer can enhance the messaging protocol (see below). You normally won't use it explicitly since we have the user API for that.

## use the user API functions

The [user API](../api/user_api.md) to the messaging protocol provides an easy way to communicate with actors.

[`request`](@ref) is a wrapper for *synchronous bidirectional communication*. It creates a link internally and sends it with the communication parameters as a `Call` (or another given message type) to the actor. So it is a shortcut for the above explicit use:

```julia
julia> request(myactor, 1,2,3)
6
```

[`call`](@ref) can do both asynchronous and synchronous (bidirectional) communication. If you give it a link, the actor will respond to that:

```julia
julia> call(myactor, me, 1, 2, 3)
Actors.Call((1, 2, 3), Link{Channel{Any}}(Channel{Any}(32), 1, :local))

julia> receive(me).y
6
```

Without a link as second parameter, it will use a `request` and work synchronously:

```julia
julia> call(myactor, 1, 2, 3)
6
```

There are more [user API](../api/user_api.md) functions for accessing the [messaging protocol](../manual/protocol.md).

## write your own actor API

## enhance the messaging protocol
