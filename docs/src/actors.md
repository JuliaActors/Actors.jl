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

julia> request(act1)                           # call it
2

julia> using Distributed

julia> addprocs(1);

julia> @everywhere using Actors

julia> act2 = spawn(Func(println), pid=2)       # start a remote actor on pid 2 with a println behavior
Link{RemoteChannel{Channel{Any}}}(RemoteChannel{Channel{Any}}(2, 1, 232), 2, :remote)

julia> request(act2, "Tell me where you are!") # and call it with an argument
      From worker 2:    Tell me where you are!
```

Actors are created with a behavior function and eventually partial arguments to it. We send them the remaining arguments later with a message.

## Links

Creating an actor returnes a [`Link`](@ref) over which it can receive messages. This is its only representation.

## Messages

Actors act and communicate asynchronously. There are only two functions to interact with them:

- [`send`](@ref): send a message to an actor,
- [`receive`](@ref): receive a message from an actor.

If you send an actor any message, it tries to execute its behavior function with it.

```julia
julia> f(a, b, c) = a + b + c
f (generic function with 1 method)

julia> act3 = spawn(Func(f, 1))   # create an actor with f(1)
Link{Channel{Any}}(Channel{Any}(sz_max:32,sz_curr:0), 1, :default)

julia> send(act3, 2, 3)           # now it executes f(1, 2, 3)
(2, 3)

julia> query(act3, :res)          # query the result
6

julia> call!(act3, 2, 2)          # call! does a synchronous communication
5

julia> send(act3, 2, 3, 4, 5)     # this makes the actor fail
(2, 3, 4, 5)

julia> query(act3, :res)          # it doesn't respond anymore
Actors.Timeout()

julia> istaskfailed(act3)
true

ulia> Actors.info(act3)           # get the stacktrace
Task (failed) @0x0000000106e37190
MethodError: no method matching f(::Int64, ::Int64, ::Int64, ::Int64, ::Int64)
Closest candidates are:
  f(::Any, ::Any, ::Any) at REPL[48]:1
....
```

Actors follow a message [protocol](protocol.md) if they get a message of type [`Msg`](@ref). This can be extended by a user.

## Behavior

When an actor receives a message, it combines any partial arguments known to it with the message arguments and executes its behavior function.

```julia
julia> mystack = spawn(Func(stack_node, StackNode(nothing, Link()))); # create an actor with a partial argument
```

`mystack` represents an actor with a `stack_node` behavior and a partial argument `StackNode(nothing, Link())`. When it eventually receives a message ...

```julia
julia> send(mystack, Push(1))        # push 1 on the stack
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

Those functions are wrappers to the message [protocol](protocol.md) and to [`send`](@ref).

Actors can also operate on themselves, or rather they send messages to themselves:

- [`become`](@ref): an actor switches its own behavior,
- [`self`](@ref): an actor gets a link to itself,
- [`stop`](@ref): an actor stops.

## Bidirectional Messages

What if you want to receive a reply from an actor? Then there are two possibilities:

1. [`send`](@ref) a message to an actor and then [`receive`](@ref) the [`Response`](@ref) asynchronously,
2. [`request`](@ref): send a message to an actor, **block** and receive the result synchronously.

The following functions do this for specific duties:

- [`call!`](@ref) an actor to execute its behavior function and to send the result,
- [`exec!`](@ref): tell an actor to execute a function and to send the result,
- [`query`](@ref) tell an actor's to send one of its internal state variables.

If you provide those functions with a return link, they will use [`send`](@ref) and you can then [`receive`](@ref) the [`Response`](@ref) from the return link later. If you 
don't provide a return link, they will use [`request`](@ref) to block and return the result. Note that you should not use blocking when you need to be strictly responsive.

## Using the API

The [API](api.md) functions allow to work with actors without using messages explicitly:

```@repl actors
using Actors, .Threads
import Actors: spawn
act4 = spawn(Func(+, 4))       # start an actor adding to 4
exec!(act4, Func(threadid))    # ask it its threadid
cast!(act4, 4)                 # cast it 4
query(act4, :res)              # query the result
become!(act4, *, 4);           # switch the behavior to *
call!(act4, 4)                 # call it with 4
exec!(act4, Func(broadcast, cos, pi .* (-2:2))) # tell it to exec any function
Actors.diag(act4)              # check it
exit!(act4)                    # stop it
act4.chn.state
Actors.diag(act4)              # try to check it again
```

## Actor Tasks

Actor tasks execute one computation, mostly without communicating with other actors. They can be used to compute values asynchronously.

You can start actor tasks with [`async`](@ref) and get their result with [`await`](@ref).

```@repl actors
t = async(Func(^, 123, 456));
await(t)
```

## Actor Registry

If a parent actor or worker process creates a new actor, the link to it is only locally known. It has to be sent to all other actors that want to communicate with it.

Alternatively an actor link can be registered under a name (a `Symbol`). Then any actor in the system can communicate with it using that name.

```julia
julia> using Actors, Distributed

julia> import Actors: spawn

julia> addprocs(1);

julia> @everywhere using Actors

julia> @everywhere function ident(id, from)
           id == from ?
               ("local actor",  id, from) :
               ("remote actor", id, from)
       end

julia> register(:act1, spawn(Func(ident, 1))) # a registered local actor
true

julia> call!(:act1, myid())                   # call! it
("local actor", 1, 1)

julia> register(:act2, spawn(Func(ident, 2), pid=2)) # a registered remote actor on pid 2
true

julia> call!(:act2, myid())                   # call! it
("remote actor", 2, 1)

julia> fetch(@spawnat 2 call!(:act1, myid())) # call! :act1 on pid 2
("remote actor", 1, 2)

julia> fetch(@spawnat 2 call!(:act2, myid())) # call! :act2 on pid 2
("local actor", 2, 2)

julia> whereis(:act1)                         # get a link to :act1
Link{Channel{Any}}(Channel{Any}(sz_max:32,sz_curr:0), 1, :default)

julia> whereis(:act2)                         # get a link to :act2
Link{RemoteChannel{Channel{Any}}}(RemoteChannel{Channel{Any}}(2, 1, 16), 2, :default)

julia> fetch(@spawnat 2 whereis(:act1))       # get a link to :act1 on pid 2
Link{RemoteChannel{Channel{Any}}}(RemoteChannel{Channel{Any}}(1, 1, 40), 1, :default)

julia> registered()                           # get a list of registered actors
2-element Array{Pair{Symbol,Link},1}:
 :act2 => Link{RemoteChannel{Channel{Any}}}(RemoteChannel{Channel{Any}}(2, 1, 16), 2, :default)
 :act1 => Link{Channel{Any}}(Channel{Any}(sz_max:32,sz_curr:0), 1, :default)

julia> fetch(@spawnat 2 registered())         # get it on pid 2
2-element Array{Pair{Symbol,Link{RemoteChannel{Channel{Any}}}},1}:
 :act2 => Link{RemoteChannel{Channel{Any}}}(RemoteChannel{Channel{Any}}(2, 1, 16), 2, :default)
 :act1 => Link{RemoteChannel{Channel{Any}}}(RemoteChannel{Channel{Any}}(1, 1, 46), 1, :default)
```

The registry works transparently across workers. All workers have access to registered actors on other workers via remote links.

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
