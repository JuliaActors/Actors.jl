#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#

using Actors, Test, .Threads
import Actors: spawn, newLink

t = Ref{Task}()
a = Ref{Int}()
a[] = 1

inca(a, b) = a[] = a[] + b

act = spawn(Func(inca, a), taskref=t)

@test t[].state == :runnable
A = request(act, Actors.Diag, 1)
@test A.mode == :default

send(act, 1)
sleep(0.1)
@test a[] == 2
@test request(act, 1) == 3
@test a[] == 3
become!(act, threadid)
@test request(act) > 1

act1 = spawn(Func(threadid), sticky=true)
@test request(act1) == 1
act2 = spawn(Func(threadid), thrd=2)
@test request(act2) == 2
