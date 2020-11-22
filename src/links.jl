#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#

function newLink(size=32; remote=false, pid=myid(), mode=nothing) 
    isnothing(mode) && (mode = remote ? :remote : :local)
    return remote ?
        Link(RemoteChannel(()->Channel(max(1, size))), pid, mode) :
        Link(Channel(max(1, size)), myid(), mode)
end
