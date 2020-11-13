#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#

using Test, SafeTestsets, Distributed

function redirect_devnull(f)
    open(@static(Sys.iswindows() ? "nul" : "/dev/null"), "w") do io
        redirect_stdout(io) do
            f()
        end
    end
end

length(procs()) == 1 && addprocs(1)

@safetestset "Basics"        begin include("test_basics.jl") end
@testset "Distributed"       begin include("test_distr.jl") end
