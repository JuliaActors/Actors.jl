#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#

newLink(size=32; remote=false, pid=myid()) = remote ?
    Link(RemoteChannel(()->Channel(max(1, size))), pid, :remote) :
    Link(Channel(max(1, size)), myid(), :local)
