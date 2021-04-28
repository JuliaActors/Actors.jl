#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#

using Actors, Distributed, Test
import Actors: spawn

length(procs()) == 1 && addprocs(1)

if length(workers()) > 0
    # @everywhere using Pkg
    # @everywhere Pkg.activate(".")
    @everywhere using Actors

    @everywhere mutate(a) = a[:] = a .+ 1
    a = [1, 1, 1]
    mutate(a)
    @test a == [2,2,2]

    mut = spawn(Bhv(mutate), pid=2)
    @test request(mut, a) == [3,3,3]
    @test a == [2,2,2]
    become!(mut, myid)
    @test request(mut) == 2
    @test info(mut).pid == 2
    send(mut, :boom)
    sleep(0.5)
    @test info(mut).exception.ex isa MethodError
end
