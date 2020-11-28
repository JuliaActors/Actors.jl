#
# This file is part of the YAActL.jl Julia package, MIT license
#
# Paul Bayer, 2020
#

function __init__()
    if myid() == 1
        global _REG = Link(
            RemoteChannel(()->spawn(Func(_reg, Dict{Symbol, Link}())).chn), 
            1, :registry)
    else
        tmp = spawn(Func(()->Actors._REG), pid=1)
        global _REG = call(tmp)
        exit!(tmp)
    end
end
