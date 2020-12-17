#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#

using Actors, Test
import Actors: spawn

fail() = nonexistent()

act = spawn(fail)

@test Actors.diag(act) == :ok
@test Actors.info(act) == :runnable
send(act)
sleep(0.1)
@test istaskfailed(act)
@test Actors.info(act) == act.chn.excp.task
