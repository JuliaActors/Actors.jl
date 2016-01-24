# This file is a part of Actors.jl, licensed under the MIT License (MIT).

using Actors

import EasyPkg
@EasyPkg.using_BaseTest


@testset "Basic Actor operations" begin
    echo_actor = @actor begin
        while true
            const sender, msg = receive()
            tell(sender, msg)
        end
    end

    try
        @testset "tell() and receive()" begin
            tell(echo_actor, "foo")
            tell(echo_actor, "bar")

            @test receive() == (echo_actor => "foo")
            @test receive() == (echo_actor => "bar")
        end

        @testset "ask()" begin
            @test ask(echo_actor, "baz") == "baz"
        end

    finally
        @testset "kill()" begin
            try
                kill(echo_actor, 42)
            catch e
                @test e == 42
            end
        end
    end
end
