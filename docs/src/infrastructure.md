# More Useful Stuff

```@meta
CurrentModule = Actors
```

`Actors` provides some more functionality going beyond the classical model.

## User Defined Messages

Often you want to define your own message types. For  defining empty messages you can use the [`@msg`](@ref) macro.  

## Actor Registry

If a parent actor or worker process creates a new actor, the link to it is only locally known. It has to be sent to all other actors that want to communicate with it.

Now let's setup a remote worker and an `ident` function:

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
```

An actor (link) can be [`register`](@ref)ed under a name (a `Symbol`). This name then is known system-wide and any other actor can communicate with it using that name:

```julia
julia> register(:act1, spawn(ident, 1))      # a registered local actor
true

julia> call(:act1, myid())                   # call it locally
("local actor", 1, 1)

julia> register(:act2, spawn(ident, 2, pid=2)) #  register a remote actor on pid 2
true

julia> call(:act2, myid())                   # call it locally
("remote actor", 2, 1)

julia> fetch(@spawnat 2 call(:act1, myid())) # call :act1 on pid 2
("remote actor", 1, 2)

julia> fetch(@spawnat 2 call(:act2, myid())) # call :act2 on pid 2
("local actor", 2, 2)
```

The registry provides three further functions:

| API function | brief description |
|:-------------|:------------------|
| [`whereis`](@ref) | return the link of a registered actor |
| [`registered`](@ref) | return an array of all registered actors |
| [`unregister`](@ref) | remove a registration |

```julia
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
