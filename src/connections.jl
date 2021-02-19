#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#

"Connection to a supervisor."
struct Super{L} <: Connection
    lk::L
end

"""
    Child{L,T}(lk::L, start, info::T)

Connection to a supervised actor or task.

# Fields
- `lk::L`: Link or Task,
- `start::Any`: callable object for restarting it,
- `info::T`: named tuple with information about restart
    strategies, timeout, pollint ...
"""
struct Child{L,T} <: Connection
    lk::L
    start::Any
    info::T
end

"Connection to a peer actor"
struct Peer{L} <: Connection
    lk::L
end

"Connection to a monitor"
struct Monitor{L} <: Connection
    lk::L
end

"Connection to a monitored actor or task"
struct Monitored{L} <: Connection
    lk::L
    action::Any
end

"""
    connect(lk::Link)

Create a connection between the calling actor and 
the actor represented by `lk`. 

Connected actors will send each other [`Exit`](@ref) 
signals. A connected actor will exit with the signaled reason 
unless it is `:normal`.

**Note:**
- An actor can be made `:sticky` with [`trapExit`](@ref) and then will not exit.
- If this is called from the `Main` scope, `lk` is 
connected to the `Actors._ROOT` actor.
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

function _monitortask(t::Task, m::Link; timeout::Real=5.0, pollint::Real=0.1)
    res = timedwait(()->t.state!=:runnable, timeout; pollint)
    res == :ok ?
        t.state == :done ?
            send(m, Down(t, :normal, nothing)) :
            send(m, Down(t, t.exception, t)) :
        send(m, Down(t, res, nothing))
end

"""
```
monitor(lk::Link, onsignal...)
monitor(t::Task, onsignal...; timeout::Real=5.0, pollint::Real=0.1)
```
Start monitoring the actor represented by `lk` or the
task `t` and execute `onsignal...` if it sends [`Down`](@ref)
or if it fails.
# Parameters
- `onsignal...`: action to take on `Down` signal: 
    - if empty, it gives a warning; 
    - if it is one argument `f`, it executes with 
      `f(msg.reason)`; 
    - if `f, args...`, it gets executed with 
      `f(args..., msg.reason)`.
- `timeout::Real=5.0`: how many seconds should a task 
    be monitored? After that a [`Down`](@ref) with
    reason `:timed_out` is sent.
- `pollint::Real=0.1`: polling interval in seconds for
    task monitoring.
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
function monitor(t::Task, onsignal...; timeout::Real=5.0, pollint::Real=0.1)
    mt = Ref{Task}()
    onsignal = isempty(onsignal) ? nothing :
        length(onsignal) == 1 ? first(onsignal) :
            Bhv(first(onsignal), onsignal[2:end]...)
    try
        act = task_local_storage("_ACT")
        mt[] = @async _monitortask(t, act.self; timeout, pollint)
        !isnothing(onsignal) && push!(act.conn, Monitored(t, onsignal))
    catch exc
        if exc isa KeyError
            mt[] = @async _monitortask(t, _ROOT; timeout, pollint)
            !isnothing(onsignal) && send(_ROOT, Connect(Monitored(t, onsignal)))
        else
            rethrow()
        end
    end
    # return :ok
    return mt
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

