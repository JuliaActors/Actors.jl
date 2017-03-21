# This file is a part of Actors.jl, licensed under the MIT License (MIT).

using Actors
using Base.Test


@testset "Basic Actor operations" begin
    echo_actor = @actor begin
        while true
            const sender, msg = actor_recv()
            send(sender, msg)
        end
    end

    try
        @testset "send() and actor_recv()" begin
            send(echo_actor, "foo")
            send(echo_actor, "bar")

            @test actor_recv() == (echo_actor => "foo")
            @test actor_recv() == (echo_actor => "bar")
        end

        @testset "ask()" begin
            @test ask(echo_actor, "baz") == "baz"
        end

    finally
        if VERSION.minor <= 4
            # Currently doesn't work right for Julia >= v0.5:
            @testset "kill()" begin
                try
                    kill(echo_actor)
                catch exc
                    @test exc == InterruptException()
                end
            end
        end
    end
end
