# This file is a part of Actors.jl, licensed under the MIT License (MIT).

@Base.Test.testset "Package Actors" begin
    include.([
        "test_actor.jl",
    ])
end
