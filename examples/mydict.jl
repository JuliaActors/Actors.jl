#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#

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

using .MyDict, .Threads

d = dictsrv(Dict{Int,Int}())

@threads for i in 1:1000
    d[i] = threadid()
end

d()
