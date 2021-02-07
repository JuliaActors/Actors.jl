#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#

const ERR_BUF = 10

_terminate!(A::_ACT, reason) = isnothing(A.term) || Base.invokelatest(A.term.f, reason)
_sticky(A::_ACT) = A.mode in (:system, :sticky, :supervisor)
function trysend(lk::Link, msg...)
    try
        send(lk, msg...)
    catch
        nothing
    end
end

function saveerror(t::Task)
    err = try
        task_local_storage("_ERR")
    catch exc
        exc isa KeyError ?
            task_local_storage("_ERR", Task[]) :
            rethrow()
    end
    length(err) ≥ ERR_BUF && popfirst!(err)
    push!(err, t)
end
saveerror(::Nothing) = nothing
function errored()
    try
        task_local_storage("_ERR")
    catch exc
        exc isa KeyError ? nothing : rethrow()
    end
end

function onerror(A::_ACT, exc)
    for c in A.conn
        c isa Monitor ?
            trysend(c.lk, Down(self(), exc, current_task())) :
            c isa Super ?
                trysend(c.lk, Exit(exc, self(), current_task(), A)) :
                trysend(c.lk, Exit(exc, self(), current_task(), nothing))
    end
end

# 
# Actors protocol on Down, Exit
#

# Down
function onmessage(A::_ACT, msg::Down)
    ix = 0
    for (i, c) in enumerate(A.conn)
        if c.lk == msg.from && c isa Monitored 
            !isnothing(c.action) ?
                c.action(msg.reason) :
                warn(msg)
            ix = i
        end
    end
    ix != 0 ?
        deleteat!(A.conn, ix) :
        warn(msg)
end

# Exit
function onmessage(A::_ACT, msg::Exit)
    for c in A.conn
        if c.lk != msg.from
            c isa Monitor ?
                trysend(c.lk, Down(self(), msg.reason)) :
                send(c.lk, Exit(msg.reason, self(), msg.task, A))
        end
    end
    _terminate!(A, msg.reason)
end
onmessage(A::_ACT, ::Val{:sticky}, msg::Exit) = onmessage(A, Val(:system), msg)
function onmessage(A::_ACT, ::Val{:system}, msg::Exit)
    if msg.reason != :normal
        saveerror(msg.task)
        warn(msg, "monitored")
    end
    ix = findfirst(c->c.lk==msg.from, A.conn)
    isnothing(ix) ? # Exit not from a connection
        A.mode = Symbol(string(A.mode)*"∇") :
        deleteat!(A.conn, ix)
end
function onmessage(A::_ACT, ::Val{:supervisor}, msg::Exit)
    !isnormal(msg.reason) && saveerror(msg.task)
    ix = findfirst(c->c.lk==msg.from, A.conn)
    if !isnothing(ix) && A.conn[ix] isa Child
        A.bhv(msg)
    elseif !isnothing(ix) && A.conn[ix] isa Peer
        if msg.reason != :normal 
            saveerror(msg.task)
            warn(msg, "from peer")
        end
    else
        for c in A.conn
            if c.lk != msg.from
                c isa Monitor ? trysend(c.lk, Down(self(), msg.reason)) :
                c isa Child   ? shutdown_child(c) :
                    send(c.lk, Exit(msg.reason, self(), msg.task, A))
            end
        end
        msg.reason != :normal && warn(msg, "supervisor")
        _terminate!(A, msg.reason)            
        A.mode = Symbol(string(A.mode)*"∇")
    end
end
