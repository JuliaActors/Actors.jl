# Actors and Julia

```@meta
CurrentModule = Actors
```

In one of his later papers (2010) Carl Hewitt wrote:

> It is important to distinguish the following:
>
> - modeling arbitrary computational systems using Actors. It is difficult to find physical computational systems (regardless of how idiosyncratic) that cannot be modeled using Actors.
> - securely implementing practical computational applications using Actors remains an active area of research and development. [^1]

We focus on the second point, namely on practical computational applications.

## Julia is Well Suited for Actors

`Actors` uses Julia's `Task`s to execute functions concurrently and `Channel`s to let them communicate. An actor has a Julia function or callable object as [behavior](behaviors.md). That gets parametrized with the arguments given to the actor at startup (acquaintances). The other arguments are delivered via messages (communication). Then an actor executes its behavior. Actors incorporate processing, storage and communication. Functions thus become responsive and composable in new ways.

## Actors Complement Julia

Actors give Julia users additional ways to deal with concurrency. Sutter and Larus justified that as follows:

> We need higher-level language abstractions, including evolutionary extensions to current imperative languages, so that existing applications can incrementally become concurrent. The programming model must make concurrency easy to understand and reason about, not only during initial development but also during maintenance. [^2]

Actors support clear, correct concurrent programs and are an alternative to sharing memory in concurrent computing:

- Share by communicating [^3] to functions and
- use functions to localize variables and
- make actors serve mutable variables without using locks.

Below I will show how you can use actors in common multi-threading or distributed Julia code.

## Multi-threading

Julia's manual encourages the use of locks [^4] in order to ensure data-race freedom. But be aware that

> they are not composable. You can’t take two correct lock-based pieces of code, combine them, and know that the result is still correct. Modern software development relies on the ability to compose libraries into larger programs, and so it is a serious difficulty that we cannot build on lock-based components without examining their implementations. [^5]

An actor controlling the access to a variable or to another resource is lock-free and there are no limits to composability. Therefore if you write multi-threaded programs which should be composable or maybe used by other programs within a lock, you might consider using `Actors`.

## Distributed Computing

Actors are location transparent. You can share their links across workers to access the same actor on different workers. If local links are sent to a remote actor, they are converted to remote links.

## [A `Dict` Server](@id dict-server)

This example shows how to implement a `Dict`-server actor that can be used in multi-threaded and distributed Julia code.

1. We implement `DictSrv` as a function object containing a link to an actor.
2. `DictSrv` gets an indexing interface.
3. The actor behavior `ds` takes a `Dict` variable as acquaintance and executes the communicated function `f` and `args...` on it. If called without arguments it returns a copy of its `Dict` variable.

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
ds(d::Dict) = copy(d)
# start dict server
dictsrv(d::Dict; remote=false) = DictSrv(spawn(ds, d, remote=remote))

export DictSrv, dictsrv

end
```

A dict server is started with `dictsrv`. It does not share its `Dict` variable. Let's try it out:

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

`Actors` provides explicit methods for fault tolerant computing used mainly in telecommunications and internet services with Erlang/OTP [^6]:

- *group* actors and force them to fail together,
- *monitor* tasks and actors and take action if they fail or time out,
- *supervise* tasks and actors and restart them if a failure occurs.

Based on that *checkpoint* and *restore* as used for  fault-tolerance in high performance computing (HPC) can be implemented.

!!! note "This is currently work in progress!"
    Those features should be considered experimental!

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
[^2]: H. Sutter and J. Larus. Software and the concurrency revolution. ACM Queue, 3(7), 2005.
[^3]: Effective Go: [Share by Communicating](https://golang.org/doc/effective_go.html#sharing)
[^4]: see [Data race freedom](https://docs.julialang.org/en/v1/manual/multi-threading/#Data-race-freedom) in the Julia manual.
[^5]: H. Sutter and J. Larus. see above
[^6]: see Joe Armstrong, 2003: [Making reliable distributed systems in the presence of software errors](https://erlang.org/download/armstrong_thesis_2003.pdf)