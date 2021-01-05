#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#

using Actors, Test, .Threads
import Actors: spawn, info, diag

const sleeptime = 0.1
t1 = Ref{Task}()
t2 = Ref{Task}()
t3 = Ref{Task}()

act1 = spawn(connect, taskref=t1)
a1   = diag(act1, 9999)
act2 = spawn(connect, taskref=t2)
a2   = diag(act2, 9999)
send(act1, act2)
sleep(sleeptime)
@test a1.conn[1] isa Actors.Peer
@test a1.conn[1].lk == act2
@test a2.conn[1] isa Actors.Peer
@test a2.conn[1].lk == act1
@test t1[].state == :runnable
@test t2[].state == :runnable
send(act1, "boom")
sleep(sleeptime)
@test t1[].state == :failed
@test t2[].state == :done

act1 = spawn(connect, taskref=t1)
act2 = spawn(connect, taskref=t2)
act3 = spawn(connect, taskref=t3)
send(act1, act2)
send(act3, act2)
sleep(sleeptime)
send(act1, "boom")
sleep(sleeptime)
@test t1[].state == :failed
@test t2[].state == :done
@test t3[].state == :done

act1 = spawn(connect, taskref=t1)
act2 = spawn(connect, taskref=t2)
act3 = spawn(connect, taskref=t3)
send(act1, act2)
send(act3, act2)
trapExit(act3)
sleep(sleeptime)
@test act3.mode == :system
send(act1, "boom")
sleep(sleeptime)
@test t1[].state == :failed
@test t2[].state == :done
@test t3[].state == :runnable
@test length(diag(act3, 99)) == 1
@test info(diag(act3, 99)[1]).exception isa MethodError
