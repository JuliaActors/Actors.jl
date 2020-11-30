#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#

using Actors
import Actors: spawn

function fib(D::Dict{Int,BigInt}, n::Int)
    get!(D, n) do
        n == 0 && return big(0)
        n == 1 && return big(1)
        return fib(D, n-1) + fib(D, n-2)
    end
end

myfib = spawn(Bhv(fib, Dict{Int,BigInt}()))

request(myfib, 1000)

