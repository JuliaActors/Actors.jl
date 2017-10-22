# This file is a part of Actors.jl, licensed under the MIT License (MIT).

import Compat.Test
Test.@testset "Package Actors" begin
    include.([
        "test_actor.jl",
    ])
end
