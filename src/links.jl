#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#

"""
    newLink(size=32; remote=false)

Create a local Link with a buffered `Channel` `size ≥ 1`.

# Parameters
- `size=32`: the size of the channel buffer,
- `remote=false`: should a remote link be created,
- `pid=myid()`: optional pid of the remote worker.
"""
newLink(size=32; remote=false, pid=myid()) = remote ?
    Link(RemoteChannel(()->Channel(max(1, size))), pid, :remote) :
    Link(Channel(max(1, size)), myid(), :local)
