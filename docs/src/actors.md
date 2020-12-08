# Understanding Actors

```@meta
CurrentModule = Actors
```

`Actors` implements the [Actor model](basics.md) using Julia's concurrency primitives:

- actors are implemented as `Task`s
- communicating over `Channel`s.

## Creating Actors

To create an actor we [`spawn`](@ref) it with a [behavior](behaviors.md):

```julia
julia> using Actors, .Threads

julia> import Actors: spawn

julia> act1 = spawn(Bhv(threadid))             # start an actor which returns its threadid
Link{Channel{Any}}(Channel{Any}(sz_max:32,sz_curr:0), 1, :local)

julia> request(act1)                           # call it
2

julia> using Distributed

julia> addprocs(1);

julia> @everywhere using Actors

julia> act2 = spawn(Bhv(println), pid=2)       # start a remote actor on pid 2 with a println behavior
Link{RemoteChannel{Channel{Any}}}(RemoteChannel{Channel{Any}}(2, 1, 232), 2, :remote)

julia> request(act2, "Tell me where you are!") # and call it with an argument
      From worker 2:    Tell me where you are!
```

Actors are created with a behavior. They execute their behavior when they receive a message.

## Actor Links

Creating an actor returns a [`Link`](@ref) over which it can receive messages. This is its only representation.

## Messages

Actors act and communicate asynchronously. There are only two functions to interact with them:

- [`send`](@ref): send a message to an actor,
- [`receive`](@ref): receive a message from an actor.

If you send an actor any message, it tries to execute its behavior function with it.

```julia
julia> f(a, b, c) = a + b + c
f (generic function with 1 method)

julia> act3 = spawn(Bhv(f, 1))    # create an actor with f(1)
Link{Channel{Any}}(Channel{Any}(sz_max:32,sz_curr:0), 1, :default)

julia> send(act3, 2, 3)           # now it executes f(1, 2, 3)
(2, 3)

julia> query(act3, :res)          # query the result
6

julia> send(act3, 2, 3, 4, 5)     # this makes the actor fail
(2, 3, 4, 5)

julia> query(act3, :res)          # it doesn't respond anymore
Actors.Timeout()

julia> istaskfailed(act3)
true

julia> Actors.info(act3)          # get the stacktrace
Task (failed) @0x0000000106e37190
MethodError: no method matching f(::Int64, ::Int64, ::Int64, ::Int64, ::Int64)
Closest candidates are:
  f(::Any, ::Any, ::Any) at REPL[48]:1
....
```

Actors follow a message [protocol](protocol.md) if they get a message of type [`Msg`](@ref). This can be extended by a user.

## Behavior

When an actor receives a message, it executes its behavior. A behavior has a behavior function with
partial arguments to it. This can be a closure 
[`Bhv`](@ref) or a function object around some data.

```julia
julia> mystack = spawn(Bhv(stack_node, StackNode(nothing, Link()))); # create an actor with a partial argument
```

`mystack` represents an actor with a `stack_node` behavior and a partial argument `StackNode(nothing, Link())`. When it eventually receives a message ...

```julia
julia> send(mystack, Push(1))        # push 1 on the stack
```

..., it executes `stack_node(StackNode(nothing, Link()), Push(1))`.

## Actor Isolation

In order to avoid race conditions actors have to be strongly isolated from each other:

1. they do not share state,
2. they must not share mutable variables.

An actor stores the behavior function and arguments to it, results of computations and more. Thus it has state and this influences how it behaves.

But it does **not share** its state variables with its environment (only for diagnostic purposes). The [API](api.md) functions above are a safe way to access actor state via messaging.

Mutable variables in Julia can be sent over local channels without being copied. Accessing those variables from multiple threads can cause race conditions. The programmer has to be careful to avoid those situations either by

- not sharing them between actors,
- copying them when sending them to actors or
- acquiring a lock around any access to data that can be observed from multiple threads. [^1]

When sending mutable variables over remote links, they are automatically copied.

## Actor Local Dictionary

Since actors are Julia tasks, they have a local dictionary in which you can store values. You can use [`task_local_storage`](https://docs.julialang.org/en/v1/base/parallel/#Base.task_local_storage-Tuple{Any}) to access it in behavior functions. But normally argument passing should be enough to handle values in actors.

[^1]: see [Data race freedom](https://docs.julialang.org/en/v1/manual/multi-threading/#Data-race-freedom) in the Julia manual.
