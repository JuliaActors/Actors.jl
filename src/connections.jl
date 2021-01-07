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

struct Monitored{L} <: Connection
    lk::L
    action::Any
end

"""
    connect(lk::Link)

Create a peer connection between the calling actor and 
the actor represented by `lk`. 

Peer connected actors will send each other [`Exit`](@ref) 
signals. A peer actor will exit with the signaled reason 
unless it is `:normal`. If it is a `:system` actor, 
a peer actor will not exit (see [`trapExit`](@ref)).

**Note:** If this is called from the `Main` scope, `lk` 
is connected as a peer to the `_ROOT` actor.
"""
function connect(lk::L) where L<:Link
    try
        act = task_local_storage("_ACT")
        if act.self != lk
            push!(act.conn, Peer(lk))
            unique!(act.conn)
            send(lk, Connect(Peer(act.self)))
        end            
    catch exc
        if exc isa KeyError
            send(_ROOT, Connect(Peer(lk)))
            send(lk, Connect(Peer(_ROOT)))
        else
            rethrow()
        end
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
    monitor(lk::Link, onsignal...)

Start monitoring the actor represented by `lk` and
execute `onsignal...` if it sends [`Down`](@ref).

# Parameters
- `onsignal...`: if empty, it gives a warning; 
    if it is one argument `f`, it executes with 
    `f(msg.reason)`; if it is `f, args...`, it gets
    executed with `f(args..., msg.reason)`.
"""
function monitor(lk::L, onsignal...) where L<:Link
    onsignal = isempty(onsignal) ? nothing :
        length(onsignal) == 1 ? first(onsignal) :
            Bhv(first(onsignal), onsignal[2:end]...)
    try
        act = task_local_storage("_ACT")
        send(lk, Connect(Monitor(act.self)))
        !isnothing(onsignal) && push!(act.conn, Monitored(lk, onsignal))
    catch exc
        if exc isa KeyError
            send(lk, Connect(Monitor(_ROOT)))
            !isnothing(onsignal) && send(_ROOT, Connect(Monitored(lk, onsignal)))
        else
            rethrow()
        end
    end
    return :ok
end

"""
    disconnect(lk::Link)

Remove the connection between the calling actor and the
actor represented by `lk`.

**Note:** If this is called from the `Main` scope, `lk` 
is disconnected from the `_ROOT` actor.
"""
function disconnect(lk::L) where L<:Link
    try
        act = task_local_storage("_ACT")
        filter!(c->c.lk!=lk, act.conn)
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

