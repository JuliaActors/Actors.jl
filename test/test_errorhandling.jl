#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#

include("delays.jl")

using Actors, Test, .Threads, .Delays
import Actors: spawn, info, diag, newLink

Base.:(==)(l1::Link, l2::Link) = hash(l1) == hash(l2)

t1 = Ref{Task}()
t2 = Ref{Task}()
t3 = Ref{Task}()

println("Testing error handling with some failures:")

# 
# test peer connections
# 
act1 = spawn(connect, taskref=t1)
a1   = diag(act1, :act)
act2 = spawn(connect, taskref=t2)
a2   = diag(act2, :act)
send(act1, act2)
@test @delayed a1.conn[1] isa Actors.Peer
@test a1.conn[1].lk == act2
@test @delayed a2.conn[1] isa Actors.Peer
@test a2.conn[1].lk == act1
@test t1[].state == :runnable
@test t2[].state == :runnable
send(act1, "boom")
@test @delayed t1[].state == :failed
@test t2[].state == :done

act1 = spawn(connect, taskref=t1)
act2 = spawn(connect, taskref=t2)
act3 = spawn(connect, taskref=t3)
send(act1, act2)
send(act3, act2)
sleep(0.5)
send(act1, "boom")
@test @delayed t1[].state == :failed
@test t2[].state == :done
@test t3[].state == :done

act1 = spawn(connect, taskref=t1)
act2 = spawn(connect, taskref=t2)
act3 = spawn(connect, taskref=t3)
send(act1, act2)
send(act3, act2)
trapExit(act3)
@test @delayed act3.mode == :sticky
send(act1, "boom")
@test @delayed t1[].state == :failed
@test t2[].state == :done
@test t3[].state == :runnable
@test length(diag(act3, :err)) == 1
@test diag(act3, :err)[1].exception isa MethodError

# disconnect
act1 = spawn(connect, taskref=t1)
act2 = spawn(connect, taskref=t2)
act3 = spawn(connect, taskref=t3)
send(act1, act2)
send(act3, act2)
a1   = diag(act1, :act)
a2   = diag(act2, :act)
a3   = diag(act3, :act)
@test @delayed a1.conn[1].lk == act2
@test @delayed a2.conn[1].lk in (act1, act3)
@test @delayed a2.conn[2].lk in (act1, act3)
@test @delayed a3.conn[1].lk == act2
become!(act1, disconnect)
send(act1, act2)
become!(act2, disconnect)
send(act2, act3)
@test @delayed isempty(a1.conn)
@test @delayed isempty(a2.conn)
@test @delayed isempty(a3.conn)

# connect and disconnect to _ROOT
act1 = spawn(threadid, taskref=t1)
connect(act1)
a1   = diag(act1, :act)
at1  = diag(act1, :task)
rt   = diag(Actors._ROOT, :act)
@test a1.conn[1].lk == Actors._ROOT
@test rt.conn[1].lk == act1
send(act1, "boom")
@test @delayed t1[].state == :failed
@test Actors.diag(Actors._ROOT, :task).state == :runnable
@test isempty(rt.conn)
errors = exec(Actors._ROOT, Actors.errored)
@test errors[end] == at1
@test errors[end].exception isa MethodError
act1 = spawn(threadid, taskref=t1)
connect(act1)
a1   = diag(act1, :act)
@test @delayed a1.conn[1].lk == Actors._ROOT
@test rt.conn[1].lk == act1
disconnect(act1)
@test @delayed isempty(a1.conn)
@test isempty(rt.conn)

# 
# test monitors
# 
me = newLink()
act1 = spawn(threadid, taskref=t1)
act2 = spawn(monitor, act1, taskref=t2)
send(act2, send, me)
a1 = diag(act1, :act)
a2 = diag(act2, :act)
@test a1.conn[1] isa Actors.Monitor
@test a1.conn[1].lk == act2
@test a2.conn[1] isa Actors.Monitored
@test a2.conn[1].lk == act1
@test a2.conn[1].action.f == send 
send(act1, "boom")
f1 = receive(me)
@test f1 isa MethodError
@test Actors.diag(act2, :task).state == :runnable
@test isempty(a2.conn)
act1 = spawn(threadid, taskref=t1)
become!(act2, monitor, act1)
send(act2)
a1 = diag(act1, :act)
@test @delayed a1.conn[1] isa Actors.Monitor
@test a1.conn[1].lk == act2
@test isempty(a2.conn)
send(act1, "boom")
@test @delayed t1[].state == :failed
@test isempty(me.chn)
act1 = spawn(threadid, taskref=t1)
become!(act2, monitor, act1)
send(act2, send, me)
a1 = diag(act1, :act)
@test @delayed a1.conn[1].lk == act2
@test a2.conn[1].lk == act1
become!(act2, demonitor)
send(act2, act1)
@test @delayed isempty(a1.conn)
@test isempty(a2.conn)

# monitor with _ROOT
act1 = spawn(threadid, taskref=t1)
monitor(act1, send, me)
a1 = diag(act1, :act)
rt = diag(Actors._ROOT, :act)
@test @delayed a1.conn[1] isa Actors.Monitor
@test a1.conn[1].lk == Actors._ROOT
@test rt.conn[1] isa Actors.Monitored
@test rt.conn[1].lk == act1
@test rt.conn[1].action.f == send 
send(act1, "boom")
f1 = receive(me)
@test f1 isa MethodError
@test Actors.diag(Actors._ROOT, :task).state == :runnable
@test isempty(rt.conn)
act1 = spawn(threadid, taskref=t1)
monitor(act1)
a1 = diag(act1, :act)
@test @delayed a1.conn[1] isa Actors.Monitor
@test a1.conn[1].lk == Actors._ROOT
@test isempty(rt.conn)
send(act1, "boom")
@test @delayed isempty(me.chn)
act1 = spawn(threadid, taskref=t1)
monitor(act1, send, me)
a1 = diag(act1, :act)
rt = diag(Actors._ROOT, :act)
@test a1.conn[1].lk == Actors._ROOT
@test rt.conn[1].lk == act1
demonitor(act1)
a1 = diag(act1, :act)
rt = diag(Actors._ROOT, :act)
@test isempty(a1.conn)
@test isempty(rt.conn)

# monitor a task
struct Stop end
me = newLink()
tc = Channel(1)
function ttask(ch)
    while true
        msg = take!(ch) 
        msg isa Stop ? break : error(msg)
    end
end
tt = Threads.@spawn ttask(tc)
act1 = spawn(Bhv(monitor, tt, timeout=2), taskref=t1)
mt = call(act1, send, me)
@test mt[].state == :runnable
a1 = diag(act1, :act)
@test @delayed a1.conn[1] isa Actors.Monitored
@test a1.conn[1].lk == tt
@test receive(me) == :timed_out
@test isempty(a1.conn)
mt = call(act1, send, me)
@test mt[].state == :runnable
put!(tc, Stop())
@test receive(me) == :normal
@test mt[].state == :done
@test tt.state == :done
tt = Threads.@spawn ttask(tc)
become!(act1, Bhv(monitor, tt, timeout=2))
mt = call(act1, send, me)
@test mt[].state == :runnable
put!(tc, "boom")
msg = receive(me)
@test msg isa ErrorException
@test msg.msg == "boom"
@test tt.state == :failed
@test mt[].state == :done
@test isempty(a1.conn)
