#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#

include("delays.jl")

using Actors, Test, .Delays

const fname = "test.x"

d = Dict(
    "test"  => [(1, 2, 3), (4, 5, 6)],
    "test1" => [("a", "b", "c")]
    )

cp = checkpointing(fname)
checkpoint(cp, "test", 1,2,3)
@test restore(cp, "test") == (1,2,3)
checkpoint(cp, "test", 4,5,6)
@test restore(cp, "test") == (4,5,6)
checkpoint(cp, "test1", "a","b","c")

@test get_checkpoints(cp) == d
save_checkpoints(cp)
@test @delayed isfile(fname)
exit!(cp)
@test @delayed info(cp) == :done
cp = checkpointing(fname)
load_checkpoints(cp, fname)
@test get_checkpoints(cp) == d

rm(fname)
