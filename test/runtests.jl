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

@safetestset "Basics"         begin include("test_basics.jl") end
@testset "Distributed"        begin include("test_distr.jl") end
@safetestset "Communication"  begin include("test_com.jl") end
@safetestset "Error handling" begin include("test_errorhandling.jl") end
@safetestset "Supervision"    begin include("test_supervision.jl") end
@safetestset "Checkpointing"  begin include("test_checkpointing.jl") end
@safetestset "API"            begin include("test_api.jl") end
@safetestset "Diagnosis"      begin include("test_diag.jl") end
@testset "Registry"           begin include("test_registry.jl") end
@safetestset "Utilities"      begin include("test_utils.jl") end

println("running examples, output suppressed!")
redirect_devnull() do
    @safetestset "Factorial"     begin include("../examples/factorial.jl") end
    @safetestset "Fib"           begin include("../examples/fib.jl") end
    @safetestset "Simple"        begin include("../examples/simple.jl") end
    @safetestset "Stack"         begin include("../examples/stack.jl") end
end
