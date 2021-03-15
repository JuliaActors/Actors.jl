#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#

include("delays.jl")

using Actors, Distributed, Test, .Delays
import Actors: spawn, newLink

prcs = addprocs(2)

@everywhere using Actors

t1 = Ref{Task}()
me = newLink()

sv = supervisor()
act1 = spawn(+, 10, pid=prcs[1])
act2 = spawn(+, 20, pid=prcs[1])
act3 = spawn(+, 30, pid=prcs[2])

rfd = Actors.rnfd_start(sv, taskref=t1)
ra = Actors.diag(rfd, :act)
ra.bhv.sv.chn = me.chn     # redirect rnfd supervisor link to me
send(rfd, Actors.Add(act1))
send(rfd, Actors.Add(act2))
send(rfd, Actors.Add(act3))
@test @delayed length(ra.bhv.lks) == 3
@test @delayed length(ra.bhv.pids) == 2

sleep(1)
@test isempty(me.chn)
rmprocs(prcs[1])
@test @delayed !isempty(me.chn)
@test @delayed length(ra.bhv.lks) == 1
@test @delayed length(ra.bhv.pids) == 1
@test ra.bhv.pids[1] == prcs[2]
@test length(me.chn.data) == 1
ex = take!(me.chn)
@test ex.reason isa ProcessExitedException
@test ex.reason.worker_id == prcs[1]

rmprocs(prcs[2])
@test @delayed !isempty(me.chn)
@test @delayed isempty(ra.bhv.lks)
@test @delayed isempty(ra.bhv.pids)
ex = take!(me.chn)
@test ex.reason isa ProcessExitedException
@test ex.reason.worker_id == prcs[2]
