#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#

using Actors, Test

t = Ref{Task}()
a = Ref{Int}()
a[] = 1

inca(a, b) = a[] = a[] + b

act = spawn(Func(inca, a), taskref=t)

@test t[].state == :runnable
send!(act, 1)
sleep(0.1)
@test a[] == 2
