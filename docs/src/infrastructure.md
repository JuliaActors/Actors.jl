# Infrastructure

```@meta
CurrentModule = Actors
```

## Actor Tasks

Actor tasks execute one computation, mostly without communicating with other actors. They can be used to compute values asynchronously.

You can start actor tasks with [`async`](@ref) and get their result with [`await`](@ref).

```@repl
using Actors
t = async(Bhv(^, 123, 456));
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

julia> register(:act1, spawn(Bhv(ident, 1))) # a registered local actor
true

julia> call(:act1, myid())                   # call it
("local actor", 1, 1)

julia> register(:act2, spawn(Bhv(ident, 2), pid=2)) # a registered remote actor on pid 2
true

julia> call(:act2, myid())                   # call it
("remote actor", 2, 1)

julia> fetch(@spawnat 2 call(:act1, myid())) # call :act1 on pid 2
("remote actor", 1, 2)

julia> fetch(@spawnat 2 call(:act2, myid())) # call :act2 on pid 2
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
