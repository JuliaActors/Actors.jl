#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#

#
# this whole thing will be replaced by
# using ActorInterfaces.Classic
#

abstract type Addr end
abstract type Actor end
function send! end
function spawn end
function become end
function onmessage end
function self end
