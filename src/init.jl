#
# This file is part of the Actors.jl Julia package, MIT license
#
# Paul Bayer, 2020
#

_root(d::Dict{Symbol,Any}) = d
_root(d::Dict{Symbol,Any}, key::Symbol, val) = d[key] = val

function __init__()
    if myid() == 1
        global _REG = Link(
            RemoteChannel(()->spawn(_reg, Dict{Symbol, Link}()).chn), 
            1, :registry)
        global _ROOT = Link(
            RemoteChannel(()->spawn(_root, Dict{Symbol,Any}(:start=>now())).chn),
            1, :root)
        update!(_ROOT, :system, s=:mode)
    else
        tmp = spawn(()->Actors._REG, pid=1)
        global _REG = call(tmp)
        become!(tmp, ()->Actors._ROOT)
        global _ROOT = call(tmp)
        exit!(tmp)
    end
end
