#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#

const ERR_BUF = 10
const _WARN = [true]

_terminate!(A::_ACT, reason) = isnothing(A.term) || Base.invokelatest(A.term.f, reason)

function saveerror(lk::Link)
    err = Link[]
    try
        err = task_local_storage("_ERR")
    catch exc
        exc isa KeyError ?
            err = task_local_storage("_ERR", Link[]) :
            rethrow()
    end
    length(err) ≥ ERR_BUF && popfirst!(err)
    push!(err, lk)
end
function errored()
    try
        return task_local_storage("_ERR")
    catch exc
        exc isa KeyError && return nothing
        rethrow()
    end
end

function onerror(A::_ACT, exc)
    for c in A.conn
        c isa Monitor ?
            send(c.lk, Down(self(), exc, current_task())) :
            c isa Parent ?
                send(c.lk, Exit(self(), exc, self(), A)) :
                send(c.lk, Exit(self(), exc, self(), nothing))
    end
end

# 
# Actors protocol on Down, Exit, Stop
#

# Down
function onmessage(A::_ACT, msg::Down)

    function warn(msg)
        enable_finalizers(false)
        if msg.reason isa Exception
            @warn "Down: $(msg.task), $(msg.task.exception)"
        else
            @warn "Down: $(msg.reason)"
        end
        enable_finalizers(true)
    end

    ix = 0
    for (i, c) in enumerate(A.conn)
        if c.lk == msg.from && c isa Monitored 
            !isnothing(c.action) ?
                c.action(msg.reason) :
                _WARN[1] && warn(msg)
            ix = i
        end
    end
    ix != 0 ?
        deleteat!(A.conn, ix) :
        _WARN[1] && warn(msg)
end

# Exit
function onmessage(A::_ACT, msg::Exit)
    for c in A.conn
        c.lk != msg.from && send(c.lk, Exit(self(), msg.reason, msg.link, msg.state))
    end
    _terminate!(A, msg.reason)
    throw(ActorExit(msg.reason))
end
function onmessage(A::_ACT, ::Val{:system}, msg::Exit)
    if msg.reason != :normal
        saveerror(msg.link)
        if _WARN[1]
            enable_finalizers(false)
            if msg.reason isa Exception && !isnothing(msg.link.chn.excp)
                t = msg.link.chn.excp.task
                @warn "Exit: $t, $(t.exception)"
            else
                @warn "Exit: $(msg.reason)"
            end
            enable_finalizers(true)
        end
    end
    ix = findfirst(c->c.lk==msg.from, A.conn)
    if !isnothing(ix)
        # eventually restart a child
        deleteat!(A.conn, ix)
    end
end

# Stop
function onmessage(A::_ACT, msg::Stop)
    for c in A.conn
        if c.lk != msg.from 
            c isa Monitor ?
                send(c.lk, Down(self(), msg.reason)) :
                send(c.lk, Exit(self(), msg.reason, nothing, nothing))
        end
    end
    _terminate!(A, msg.reason)
end
