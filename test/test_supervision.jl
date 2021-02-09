#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#

using Actors, Test, .Threads
import Actors: spawn, info, diag, newLink

const sleeptime = 0.5
t1 = Ref{Task}()
t2 = Ref{Task}()
t3 = Ref{Task}()

sv = supervisor(taskref=t1)
a1 = diag(sv, :act)
@test t1[].state == :runnable
@test sv.mode == :supervisor
@test a1.mode == :supervisor
@test a1.bhv isa Actors.Supervisor
@test a1.bhv.strategy == :one_for_one
@test isempty(which_children(sv))

act2 = spawn(threadid, taskref=t2)
exec(act2, supervise, sv, threadid)
a2 = diag(act2, :act)
@test a2.conn[1] isa Actors.Super
@test a2.conn[1].lk == sv
@test a1.conn[1] isa Actors.Child
@test a1.conn[1].lk == act2
@test a1.conn[1].start == threadid
@test a1.conn[1].restart == :transient
@test isempty(a1.bhv.rtime)
@test length(which_children(sv)) == 1

println("Testing supervision with failures:")
# test actor restart
oldch2 = act2.chn
oldtsk = t2[]
# first failure
send(act2, "boom")
sleep(sleeptime)
a2 = diag(act2, :act)
@test t2[].state == :failed
@test t1[].state == :runnable
@test oldch2 != act2.chn
t2[] = diag(act2, :task)
@test oldtsk != t2[]
@test t2[].state == :runnable
@test length(a1.bhv.rtime) == 1
@test oldtsk == diag(sv, :err)[1]
@test a1.conn[1] isa Actors.Child
@test a1.conn[1].lk == act2
@test a1.bhv.childs[1].lk == act2
@test a2.conn[1].lk == sv
# second failure
send(act2, "boom")
sleep(sleeptime)
@test t1[].state == :runnable
@test t2[].state == :failed
t2[] = diag(act2, :task)
@test length(a1.bhv.rtime) == 2
# third failure
send(act2, "boom")
sleep(sleeptime)
@test t1[].state == :runnable
# fourth failure
send(act2, "boom")
sleep(sleeptime)
@test t1[].state == :done

# test task supervision
tvar = [0]
function ttask(sv::Link, delay, fail=false)
    supervise(sv, ()->ttask(sv, delay, fail))
    sleep(delay)
    tvar[1] += 1
    fail && error("Task test error!")
    unsupervise(sv)
end

println("supervisor restart!")
sv = supervisor(taskref=t1)
t = Threads.@spawn ttask(sv, sleeptime*2)
a1 = diag(sv, :act)
sleep(sleeptime)
@test a1.conn[1] isa Actors.Child
@test a1.conn[1].lk == t
@test a1.bhv.childs[1].lk == t
sleep(sleeptime*2)
@test isempty(a1.conn)
@test isempty(a1.bhv.childs)
@test t.state == :done
@test tvar[1] == 1
@test t1[].state == :runnable

# test task restart
t = Threads.@spawn ttask(sv, sleeptime, true)  # with failure
sleep(sleeptime)
@test t1[].state == :runnable
sleep(sleeptime*4) # 3rd and 4th error
@test t1[].state == :done
@test tvar[1] == 5

# supervisor shutdown
sv = supervisor(taskref=t1)
act2 = spawn(threadid, taskref=t2)
exec(act2, supervise, sv, threadid)
sleep(sleeptime)
exit!(sv, :shutdown)
sleep(sleeptime)
@test t1[].state == :done
@test t2[].state == :done
