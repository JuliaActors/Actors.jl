# `Actors` and Julia

```@meta
CurrentModule = Actors
```

> It is important to distinguish the following:
>
> - modeling arbitrary computational systems using Actors. It is difficult to find physical computational systems (regardless of how idiosyncratic) that cannot be modeled using Actors.
> - securely implementing practical computational applications using Actors remains an active area of research and development. [^1]

## Julia is Well Suited for Actors

`Actors` implements the [Actor model](basics.md) using Julia's concurrency primitives:

- Actors are implemented as `Task`s.
- They communicate over `Channel`s.

Both tasks and channels could be modeled as actors, but they are not. Thus `Actors` is a library and not "Actors all the way down" [^2].

Given its concurrency primitives, particularly Julia's expressiveness with functions allows a practical implementation of the Actor model:

1. Actors are created with functions or functors as behaviors which
2. can be partially applied to acquaintance parameters.
3. Communication parameters get delivered via messages causing an actor to execute its behavior.

## `Actors` Complements Julia

Actors allows Julia users to complement and enrich their programs where they find them useful. Sutter and Larus justified that as follows:

> We need higher-level language abstractions, including evolutionary extensions to current imperative languages, so that existing applications can incrementally become concurrent. The programming model must make concurrency easy to understand and reason about, not only during initial development but also during maintenance. [^3]

Actors make it easier to write clear, correct concurrent programs and offer better alternatives to sharing memory in concurrent computing:

- Share by communicating [^4] to functions and
- use functions to localize variables and
- make actors serve mutable variables without using locks.

Below I will show how you can use actors in common multi-threading or distributed Julia code.

## Multi-threading

The Julia manual encourages the use of locks [^5] in order to ensure data-race freedom. But be aware that

> they are not composable. You can’t take two correct lock-based pieces of code, combine them, and know that the result is still correct. Modern software development relies on the ability to compose libraries into larger programs, and so it is a serious difficulty that we cannot build on lock-based components without examining their implementations. [^6]

An actor controlling the access to a variable or to another resource is lock-free and there are no limits to composability. Therefore if you write multi-threaded programs which should be composable or maybe used by other programs within a lock, you might consider using `Actors`.

## Distributed Computing

Actors are location transparent. You can share their links across workers to access the same actor on different workers. If local links are sent to a remote actor, they are converted to remote links.

## [A `Dict` Server](@id dict-server)

This example shows how to implement a `Dict`-server actor that can be used in multi-threaded and distributed Julia code:

```julia
# examples/mydict.jl

module MyDict
using Actors
import Actors: spawn

struct DictSrv{L}
    lk::L
end
(ds::DictSrv)() = call(ds.lk)
(ds::DictSrv)(f::Function, args...) = call(ds.lk, f, args...)
# indexing interface
Base.getindex(d::DictSrv, key) = call(d.lk, getindex, key)
Base.setindex!(d::DictSrv, value, key) = call(d.lk, setindex!, value, key)

# dict server behavior
ds(d::Dict, f::Function, args...) = f(d, args...)
ds(d::Dict) = d
# start dict server
dictsrv(d::Dict; remote=false) = DictSrv(spawn(ds, d, remote=remote))

export DictSrv, dictsrv

end
```

This module implements a `DictSrv` type with an indexing interface. A dict server is started with `dictsrv`. Let's try it out:

```julia
julia> include("examples/mydict.jl")
Main.MyDict

julia> using .MyDict, .Threads

julia> d = dictsrv(Dict{Int,Int}())
DictSrv{Link{Channel{Any}}}(Link{Channel{Any}}(Channel{Any}(sz_max:32,sz_curr:0), 1, :default))

julia> @threads for i in 1:1000
           d[i] = threadid()
       end

julia> d()
Dict{Int64,Int64} with 1000 entries:
  306 => 3
  29  => 1
  74  => 1
  905 => 8
  176 => 2
  892 => 8
  285 => 3
  318 => 3
  873 => 7
  975 => 8
  ⋮   => ⋮

julia> d[892]
8
```

All available threads did concurrently fill our served dictionary with their thread ids. Actor access to the dictionary happens almost completely behind the scenes.

Now we try it out with distributed computing:

```julia
julia> using Distributed

julia> addprocs();

julia> nworkers()
17

julia> @everywhere include("examples/mydict.jl")

julia> @everywhere using .MyDict

julia> d = dictsrv(Dict{Int,Int}(), remote=true)
DictSrv{Link{RemoteChannel{Channel{Any}}}}(Link{RemoteChannel{Channel{Any}}}(RemoteChannel{Channel{Any}}(1, 1, 278), 1, :default))

julia> @spawnat :any d[myid()] = rand(Int)
Future(4, 1, 279, nothing)

julia> @spawnat 17 d[myid()] = rand(Int)
Future(17, 1, 283, nothing)

julia> d()
Dict{Int64,Int64} with 2 entries:
  4  => -4807958210447734689
  17 => -8998327833489977098

julia> fetch(@spawnat 10 d())
Dict{Int64,Int64} with 2 entries:
  4  => -4807958210447734689
  17 => -8998327833489977098
```

The remote `DictSrv` actor is available on all workers.

## Fault Tolerance

!!! note "This has yet to be developed!"

    This will be implemented with the next major version.

## Actor Isolation

In order to avoid race conditions actors have to be strongly isolated from each other:

1. they do not share state,
2. they must not share mutable variables.

An actor stores the behavior function and arguments to it, results of computations and more. Thus it has state and this influences how it behaves.

But it does **not share** its state variables with its environment (only for diagnostic purposes). The [API](api.md) functions above are a safe way to access actor state via messaging.

Mutable variables in Julia can be sent over local channels without being copied. Accessing those variables from multiple threads can cause race conditions. The programmer has to be careful to avoid those situations either by

- not sharing them between actors,
- copying them when sending them to actors or
- representing them by an actor.

When sending mutable variables over remote links, they are automatically copied.

## Actor Local Dictionary

Since actors are Julia tasks, they have a local dictionary in which you can store values. You can use [`task_local_storage`](https://docs.julialang.org/en/v1/base/parallel/#Base.task_local_storage-Tuple{Any}) to access it in behavior functions. But normally argument passing should be enough to handle values in actors.

[^1]: Carl Hewitt. Actor Model of Computation: Scalable Robust Information Systems.- [arXiv:1008.1459](https://arxiv.org/abs/1008.1459)
[^2]: That is to paraphrase Dale Schumacher's wonderful blog [Actors all the way down](http://www.dalnefre.com/wp).
[^3]: H. Sutter and J. Larus. Software and the concurrency revolution. ACM Queue, 3(7), 2005.
[^4]: Effective Go: [Share by Communicating](https://golang.org/doc/effective_go.html#sharing)
[^5]: see [Data race freedom](https://docs.julialang.org/en/v1/manual/multi-threading/#Data-race-freedom) in the Julia manual.
[^6]: H. Sutter and J. Larus. see above
