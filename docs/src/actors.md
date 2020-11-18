# Actors

```@meta
CurrentModule = Actors
```

`Actors` implements the classical Actor Model [^1]. Actors are *created* as Julia tasks running on a computer or in a network and are represented by links over which they can *send* messages [^2]. If they receive a message, they execute a *behavior function*. 

## Start

To create an actor we [`spawn`](@ref) it with a [behavior](behaviors.md) function:

```julia
julia> using Actors, .Threads

julia> import Actors: spawn

julia> act1 = spawn(Func(threadid))             # start an actor which returns its threadid
Link{Channel{Any}}(Channel{Any}(sz_max:32,sz_curr:0), 1, :local)

julia> request!(act1)                           # call it
2

julia> using Distributed

julia> addprocs(1);

julia> @everywhere using Actors

julia> act2 = spawn(Func(println), pid=2)       # start a remote actor on pid 2 with a println behavior
Link{RemoteChannel{Channel{Any}}}(RemoteChannel{Channel{Any}}(2, 1, 232), 2, :remote)

julia> request!(act2, "Tell me where you are!") # and call it with an argument
      From worker 2:    Tell me where you are!
```

Actors are created with a behavior function and eventually partial arguments to it. We can then send them the remaining arguments later.

## Links

The actor returned a [`Link`](@ref) over which it can receive messages. This is its only representation.

## Messages

Actors act and communicate asynchronously. There are only two functions to interact with them:

- [`send!`](@ref): send a message to an actor,
- [`receive!`](@ref): receive a message from an actor.

Actors follow a message [protocol](protocol.md) if they get a message of type [`Msg`](@ref). This can be extended by a user.

## Behavior

When an actor receives a message, it combines any partial arguments known to it with the message arguments and executes its behavior function.

```julia
julia> mystack = spawn(Func(stack_node, StackNode(nothing, Link()))); # create an actor with a partial argument
```

`mystack` represents an actor with a `stack_node` behavior and a partial argument `StackNode(nothing, Link())`. When it eventually receives a message ...

```julia
julia> send!(mystack, Push(1))        # push 1 on the stack
```

..., it executes `stack_node(StackNode(nothing, Link()), Push(1))`.

## Actor Control

Actors can be controlled with the following functions:

- [`become!`](@ref): cause an actor to switch its behavior,
- [`cast!`](@ref): cause an actor to execute its behavior function,
- [`exit!`](@ref): cause an actor to terminate,
- [`init!`](@ref): tell an actor to execute a function at startup,
- [`term!`](@ref): tell an actor to execute a function when it terminates,
- [`update!`](@ref): update an actor's internal state.

Those functions are wrappers to [internal messages](protocol.md) and to [`send!`](@ref).

Actors can also operate on themselves, or rather they send messages to themselves:

- [`become`](@ref): an actor switches its own behavior,
- [`self`](@ref): an actor gets a link to itself,
- [`stop`](@ref): an actor stops.

## Bidirectional Messages

What if you want to receive a reply from an actor? Then there are two possibilities:

1. [`send!`](@ref) a message to an actor and then [`receive!`](@ref) the [`Response`](@ref) asynchronously,
2. [`request!`](@ref): send a message to an actor, **block** and receive the result synchronously.

The following functions do this for specific duties:

- [`call!`](@ref) an actor to execute its behavior function and to send the result,
- [`exec!`](@ref): tell an actor to execute a function and to send the result,
- [`query!`](@ref) tell an actor's to send one of its internal state variables.

If you provide those functions with a return link, they will use [`send!`](@ref) and you can then [`receive!`](@ref) the [`Response`](@ref) from the return link later. If you 
don't provide a return link, they will use [`request!`](@ref) to block and return the result. Note that you should not use blocking when you need to be strictly responsive.

## Using the API

The [API](api.md) functions allow to work with actors without using messages explicitly:

```julia
julia> act4 = spawn(Func(+, 4))       # start an actor adding to 4
Link{Channel{Any}}(Channel{Any}(sz_max:32,sz_curr:0), 1, :local)

julia> request!(act4, 4)
8
```

## Actor Registry

...

## Actor Supervision

...

## Actor Isolation

In order to avoid race conditions actors have to be strongly isolated from each other:

1. they do not share state,
2. they must not share mutable variables.

An actor stores the behavior function and arguments to it, results of computations and more. Thus it has state and this influences how it behaves.

But it does **not share** its state variables with its environment (only for diagnostic purposes). The [API](api.md) functions above are a safe way to access actor state via messaging.

Mutable variables in Julia can be sent over local channels without being copied. Accessing those variables from multiple threads can cause race conditions. The programmer has to be careful to avoid those situations either by

- not sharing them between actors,
- copying them when sending them to actors or
- acquiring a lock around any access to data that can be observed from multiple threads. [^3]

When sending mutable variables over remote links, they are automatically copied.

## Actor Local Dictionary

Since actors are Julia tasks, they have a local dictionary in which you can store values. You can use [`task_local_storage`](https://docs.julialang.org/en/v1/base/parallel/#Base.task_local_storage-Tuple{Any}) to access it in behavior functions. But normally argument passing should be enough to handle values in actors.

[^1]: See: The [Actor Model](https://en.wikipedia.org/wiki/Actor_model) on Wikipedia and [43 Years of Actors](http://soft.vub.ac.be/Publications/2016/vub-soft-tr-16-11.pdf).
[^2]: They build on Julia's concurrency primitives  `Task` and `Channel`.
[^3]: see [Data race freedom](https://docs.julialang.org/en/v1/manual/multi-threading/#Data-race-freedom) in the Julia manual.
