# [Implement a thread-safe `Dict`](@id dict-server)

This example implements a `Dict`-server actor that can be used in multi-threaded and distributed Julia code to avoid race conditions when tasks from multiple threads access a `Dict` concurrently:

1. `DictSrv` simply is a functor containing a link to a server actor.
2. `DictSrv` gets an indexing interface. It forwards the indexing functions `getindex` and `setindex!` to the server actor.
3. The server actor's behavior `ds` takes a `Dict` variable as acquaintance and executes the communicated functions `f` with `args...` on it. If called without arguments it returns a copy of its `Dict` variable.
4. `dictsrv` creates then a `DictSrv` functor, which spawns a server actor around a given `Dict`.

```julia
# examples/mydict.jl

module MyDict
using Actors
import Actors: spawn

struct DictSrv{L}
    lk::L
end
(ds::DictSrv)(f::Function, args...) = call(ds.lk, f, args...)
(ds::DictSrv)() = call(ds.lk)

# indexing interface
Base.getindex(d::DictSrv, key) = call(d.lk, getindex, key)
Base.setindex!(d::DictSrv, value, key) = call(d.lk, setindex!, value, key)

# dict server behavior
ds(d::Dict, f::Function, args...) = f(d, args...)
ds(d::Dict) = copy(d)

# start dict server
dictsrv(d::Dict; remote=false) = DictSrv(spawn(ds, d; remote))

export DictSrv, dictsrv 

end
```

A `DictSrv` instance is created with `dictsrv`. It can be accessed like a `Dict`, but any access to its interface involves a communication. It shares its data by communicating. Let's try it out:

```julia
julia> include("examples/mydict.jl")
Main.MyDict

julia> using .MyDict, .Threads

julia> nthreads()
8

julia> d = dictsrv(Dict{Int,Int}())
DictSrv{Link{Channel{Any}}}(Link{Channel{Any}}(Channel{Any}(sz_max:32,sz_curr:0), 1, :default))

julia> @threads for i in 1:1000
           d[i] = threadid()  # write concurrently to the Dict
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

All available threads did concurrently fill our served dictionary with their thread ids. Actor access to the dictionary happens  behind the scenes.

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

This was just to show how `Actors` provides powerful abstractions to deal with concurrency.

