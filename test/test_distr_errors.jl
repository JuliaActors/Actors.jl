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
sv = supervisor(:one_for_one, 5, 60, spares=prcs[3:4], taskref=t1)
sa = Actors.diag(sv, :act)
@test sa.bhv.option[:spares] == prcs[3:4]

# start actors for supervision on remote workers
act1 = spawn(+, 10, pid=prcs[1])
act2 = spawn(+, 20, pid=prcs[1])
act3 = spawn(+, 30, pid=prcs[2])
register(:act1, act1)
register(:act2, act2)
register(:act3, act3)

# put them under supervision
supervise(sv, act1)
@test @delayed sa.bhv.childs[1].lk === act1
@test sa.bhv.childs[1].name == :act1
@test @delayed sa.bhv.childs[2].lk.mode == :rnfd
rfd = sa.bhv.childs[2].lk
ra = Actors.diag(rfd, :act)
@test ra.bhv.sv == sv
@test ra.bhv.lks[1] === act1
@test ra.bhv.pids == [prcs[1]]
supervise(sv, act2)
@test @delayed sa.bhv.childs[3].lk === act2
@test length(sa.bhv.childs) == 3
@test @delayed ra.bhv.lks[2] === act2
@test length(ra.bhv.lks) == 2

# intermezzo: test unsupervise and (rfd)(::Remove)
unsupervise(sv, act2)
@test @delayed length(sa.bhv.childs) == 2
@test @delayed length(ra.bhv.lks) == 1

supervise(sv, act2)
supervise(sv, act3)
@test @delayed length(sa.bhv.childs) == 4
@test @delayed length(ra.bhv.lks) == 3
@test ra.bhv.pids == prcs[1:2]

sleep(1)
@test isempty(sv.chn)
rmprocs(prcs[1]) # 1
sleep(1)
@test @delayed Actors.diag(sv) == :ok 2
@test @delayed act1.pid == prcs[3]
@test @delayed act2.pid == prcs[3]
@test @delayed sa.bhv.option[:spares] == prcs[4:4]
@test @delayed call(act1, 10) == 20
@test call(:act1, 10) == 20
@test @delayed call(act2, 10) == 30
@test call(:act2, 10) == 30
@test @delayed length(ra.bhv.lks) == 3
@test ra.bhv.pids == prcs[2:3]

rmprocs(prcs[2]) # 2, no spares left
sleep(1)
@test @delayed Actors.diag(sv) == :ok 2
@test @delayed act3.pid == prcs[4]
@test @delayed isempty(sa.bhv.option[:spares])
@test @delayed call(act3, 10) == 40
@test call(:act3, 10) == 40
@test @delayed length(ra.bhv.lks) == 3
@test ra.bhv.pids == prcs[3:4]

# change act2 to :temporary
sa.bhv.childs[3].info = (restart = :temporary,)
rmprocs(prcs[3]) # 3 
sleep(1)
@test @delayed Actors.diag(sv) == :ok 2
@test @delayed act1.pid == prcs[6]
@test @delayed info(act2) == ProcessExitedException(prcs[3])
@test @delayed length(sa.bhv.childs) == 3
@test @delayed length(ra.bhv.lks) == 2

# set strategy to :one_for_all
set_strategy(sv, :one_for_all)
@test @delayed sa.bhv.option[:strategy] == :one_for_all
rmprocs(prcs[4]) # 4
sleep(1)
@test @delayed Actors.diag(sv) == :ok 2
@test @delayed length(sa.bhv.childs) == 3
@test @delayed length(ra.bhv.lks) == 2

set_strategy(sv, :rest_for_one)
@test @delayed sa.bhv.option[:strategy] == :rest_for_one
rmprocs(prcs[end]) # 5
sleep(1)
@test @delayed Actors.diag(sv) == :ok 2
@test @delayed length(sa.bhv.childs) == 3
@test @delayed length(sa.bhv.rtime) == 5

rmprocs(prcs[end-1]) # 6
sleep(1)
@test @delayed info(sv) == :done
