#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#

struct Parent{L} <: Connection
    lk::L
end

struct Child{L} <: Connection
    lk::L
    restart::Symbol
end

struct Peer{L} <: Connection
    lk::L
end

struct Monitor{L} <: Connection
    lk::L
end

"""
    connect(lk::Link)

Create a peer connection between the calling actor and 
the actor represented by `lk`. Peer connected actors 
will send each other [`Exit`](@ref) signals. A peer 
actor will exit with the signaled reason unless it is
`:normal` and if it is not a `:system` actor.
"""
function connect(lk::L) where L<:Link
    act = task_local_storage("_ACT")
    if act.self != lk
        push!(act.conn, Peer(lk))
        unique!(act.conn)
        send(lk, Connect(Peer(act.self)))
    end
end
# 
# this is for child actors
#
function connect(lk::L, W::Type{Child}, restart=:transient) where L<:Link
    try
        act = task_local_storage("_ACT")
        push!(act.conn, W(lk, restart))
        unique!(act.conn)
        send(lk, Connect(Parent(act.self)))
    catch exc
        if exc isa KeyError
            send(_ROOT, Connect(W(lk, restart)))
            send(lk, Connect(Parent(_ROOT)))
        else
            rethrow()
        end
    end
end

"""
    monitor(lk::Link)

Start monitoring the actor represented by `lk`.
"""
function monitor(lk::L) where L<:Link
    try
        act = task_local_storage("_ACT")
        send(lk, Connect(Monitor(act.self)))
    catch exc
        if exc isa KeyError
            send(lk, Connect(Monitor(_ROOT)))
        else
            rethrow()
        end
    end
end

"""
    disconnect(lk::Link)

Remove the connection between the calling actor and the
actor represented by `lk`.
"""
function disconnect(lk::L) where L<:Link
    try
        act = task_local_storage("_ACT")
        filter!(c->c.x==lk, act.conn)
        send(lk, Connect(act.self, remove=true))
    catch exc
        if exc isa KeyError
            send(_ROOT, Connect(lk, remove=true))
            send(lk, Connect(_ROOT, remove=true))
        else
            rethrow()
        end
    end
end

"""
    demonitor(lk::Link)

Remove the monitoring for the given link `lk`.
"""
demonitor = disconnect

