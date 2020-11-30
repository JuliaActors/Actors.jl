#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#

using Actors, Test, .Threads

t = async(Bhv(^, 123, 456))
@test await(t) == 2409344748064316129
@test t.t.chn.state == :closed
