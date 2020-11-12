#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#


send!(lk::Link, msg) = put!(lk.chn, msg)


