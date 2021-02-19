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
exec(act2, supervise, sv)
a2 = diag(act2, :act)
@test a2.conn[1] isa Actors.Super
@test a2.conn[1].lk == sv
@test a1.conn[1] isa Actors.Child
@test a1.conn[1].lk == act2
@test isnothing(a1.conn[1].start)
@test a1.conn[1].info.restart == :transient
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

# temporary actors
sv = supervisor(taskref=t1)
act2 = spawn(threadid, taskref=t2)
exec(act2, supervise, sv, nothing, :temporary)
a2 = diag(act2, :act)
a1 = diag(sv, :act)
@test t1[].state == :runnable
@test a1.conn[1].lk == act2
@test a1.conn[1].info.restart == :temporary
send(act2, "boom")
sleep(sleeptime)
@test isempty(a1.bhv.childs)
@test isempty(a1.conn)
@test diag(sv, :err)[1] == t2[]
@test t1[].state == :runnable

# test task supervision
tvar = [0]
function ttask(tvar, delay, fail=false)
    sleep(delay)
    tvar[1] += 1
    fail && error("Task test error!")
end

println("supervisor restart!")
sv = supervisor(taskref=t1)
rt = start_task(()->ttask(tvar, sleeptime*2), sv)
a1 = diag(sv, :act)
sleep(sleeptime)
@test a1.conn[1] isa Actors.Child
@test a1.conn[1].lk == rt
@test a1.bhv.childs[1].lk == rt
sleep(sleeptime*2)
@test isempty(a1.conn)
@test isempty(a1.bhv.childs)
@test rt[].state == :done
@test tvar[1] == 1
@test t1[].state == :runnable

# test task restart
rt = start_task(()->ttask(tvar, sleeptime, true), sv)  # with failure
sleep(sleeptime)
@test t1[].state == :runnable
sleep(sleeptime*4) # 4 task errors
@test t1[].state == :done
@test tvar[1] == 5

# test restart strategies
function checkTasks(actors, tnr, equ)
    for i in eachindex(actors)
        t = diag(actors[i], :task)
        @test t.state == :runnable
        @test equ[i](tnr[i], convert(UInt, pointer_from_objref(t)))
    end
end
ctask = [Ref{Task}() for _ in 1:5]
sv = supervisor(:one_for_all, taskref=t1)
cact = [spawn(threadid, taskref=ctask[i]) for i in 1:5]
foreach(act->exec(act, supervise, sv), cact)
sleep(sleeptime)
a1 = diag(sv, :act)
@test length(a1.bhv.childs) == 5
@test length(a1.conn) == 5
ptask = map(t->convert(UInt, pointer_from_objref(t[])), ctask)
send(cact[3], "boom")
sleep(sleeptime)
checkTasks(cact, ptask, fill(!=,5))
@test length(a1.bhv.childs) == 5
@test length(a1.conn) == 5

set_strategy(sv, :rest_for_one)
ptask = map(a->convert(UInt, pointer_from_objref(diag(a,:task))), cact)
send(cact[3], "boom")
sleep(sleeptime)
@test a1.bhv.strategy == :rest_for_one
checkTasks(cact, ptask, (==,==,!=,!=,!=))

# API
ch = Channel(0)
rt = start_task(()->take!(ch), sv, timeout=Inf)
sleep(sleeptime)
@test length(which_children(sv)) == 6
@test length(which_children(sv, true)) == 6
delete_child(sv, cact[5])
delete_child(sv, rt)
put!(ch, 0)
sleep(sleeptime)
@test length(which_children(sv)) == 4
@test Actors.diag(cact[5], :task).state == :runnable
act2 = start_actor(sv) do
    threadid()
end
t = start_task(sv, timeout=Inf) do
    take!(ch)
end
sleep(sleeptime)
@test length(which_children(sv)) == 6
terminate_child(sv, act2)
sleep(sleeptime)
@test length(which_children(sv)) == 5
@test info(act2) == :done
@test count_children(sv).all == 5

# supervisor shutdown
sv = supervisor(taskref=t1)
act2 = spawn(threadid, taskref=t2)
exec(act2, supervise, sv, threadid)
sleep(sleeptime)
exit!(sv, :shutdown)
sleep(sleeptime)
@test t1[].state == :done
@test t2[].state == :done
