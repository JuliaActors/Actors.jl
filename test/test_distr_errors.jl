#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#

include("delays.jl")

using Actors, Distributed, Test, .Delays
import Actors: spawn

prcs = addprocs(6)

@everywhere using Actors

t1 = Ref{Task}()

println("Testing supervision with remote failures:")

# start a supervisor with spare nodes
sv = supervisor(spares=prcs[3:5], taskref=t1)
sa = Actors.diag(sv, :act)
@test sa.bhv.option[:spares] == prcs[3:5]

# start actors for supervision on remote workers
act1 = spawn(+, 10, pid=prcs[1])
act2 = spawn(+, 20, pid=prcs[1])
act3 = spawn(+, 30, pid=prcs[2])

# put them under supervision
supervise(sv, act1)
@test @delayed sa.bhv.childs[1].lk == act1
@test @delayed sa.bhv.childs[2].lk.mode == :rnfd
rfd = sa.bhv.childs[2].lk
ra = Actors.diag(rfd, :act)
@test ra.bhv.sv == sv
@test ra.bhv.lks[1] == act1
@test ra.bhv.pids == [prcs[1]]
supervise(sv, act2)
supervise(sv, act3)
@test @delayed length(sa.bhv.childs) == 4
@test @delayed length(ra.bhv.lks) == 3
@test ra.bhv.pids == prcs[1:2]

sleep(1)
@test isempty(sv.chn)
rmprocs(prcs[1])
@test @delayed act1.pid == prcs[3]
@test @delayed act2.pid == prcs[3]
@test @delayed sa.bhv.option[:spares] == prcs[4:5]
@test @delayed call(act1, 10) == 20
@test @delayed call(act2, 10) == 30
@test @delayed length(ra.bhv.lks) == 3
@test ra.bhv.pids == prcs[2:3]

rmprocs(prcs[2])
@test @delayed act3.pid == prcs[4]
@test @delayed sa.bhv.option[:spares] == prcs[5:5]
@test @delayed call(act3, 10) == 40
@test @delayed length(ra.bhv.lks) == 3
@test ra.bhv.pids == prcs[3:4]

rmprocs(prcs[3])
@test @delayed act1.pid == prcs[5]
@test @delayed act2.pid == prcs[5]
@test @delayed isempty(sa.bhv.option[:spares])
@test @delayed call(act1, 10) == 20
@test @delayed call(act2, 10) == 30
@test @delayed length(ra.bhv.lks) == 3

rmprocs(prcs[5])
@test @delayed act1.pid == prcs[6]
@test @delayed act2.pid == prcs[6]
@test @delayed call(act1, 10) == 20
@test @delayed call(act2, 10) == 30
@test @delayed length(ra.bhv.lks) == 3

rmprocs(prcs[4])
@test @delayed call(act3, 10) == 40
@test @delayed length(ra.bhv.lks) == 3
