#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#

"""
    newLink(size=32; remote=false, pid=myid(), mode=nothing)

Create a local Link with a buffered `Channel` `size ≥ 1`.

# Parameters
- `size=32`: the size of the channel buffer,
- `remote=false`: should a remote link be created,
- `pid=myid()`: optional pid of the remote worker,
- `mode=nothing`: if mode==nothing the mode is automatically
    set to `:local` or `:remote`.
"""
function newLink(size=32; remote=false, pid=myid(), mode=nothing) 
    isnothing(mode) && (mode = remote ? :remote : :local)
    return remote ?
        Link(RemoteChannel(()->Channel(max(1, size))), pid, mode) :
        Link(Channel(max(1, size)), myid(), mode)
end

# 
# make a remote link from a local one
# 
# this has to be reimplemented for types containing
# local links that may be sent to a remote worker
# 
_rlink(lk::Link) = lk.chn isa Channel ?
        Link(RemoteChannel(()->lk.chn), myid(), lk.mode) : lk
_rlink(t::Tuple) = Tuple(_rlink(i) for i in t)
_rlink(v::Vector) = collect(_rlink(i) for i in v)
_rlink(p::Iterators.Pairs) = pairs((; Dict(((i, _rlink(j)) for (i,j) in p))...))
_rlink(bhv::Bhv) = Bhv(bhv.f, _rlink(bhv.a)...; _rlink(bhv.kw)...)
_rlink(arg::Args) = Args(_rlink(arg.args)..., _rlink(arg.kwargs)...)
_rlink(x) = x

