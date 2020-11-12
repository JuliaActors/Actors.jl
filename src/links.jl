#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#

"""
    Link(size=32)

Create a local Link with a buffered `Channel` `size ≥ 1`.
"""
Link(size=32) = Link(Channel(max(1, size)), myid(), :local)

