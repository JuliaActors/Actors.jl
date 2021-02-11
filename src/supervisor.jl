#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#

# messages to the supervisor
struct Delete end 
struct Terminate end
struct Which end

const strategies = (:one_for_one, :one_for_all, :rest_for_one)
const restarts   = (:permanent, :temporary, :transient)

isnormal(reason) = reason in (:normal, :shutdown, :timed_out)

"""
```
Supervisor
```
Supervisor functor for actors, has data and behavior.

# Data (acquaintances)
- `strategy::Symbol`: supervision strategy, can be 
    either `:one_for_one`, `:one_for_all` or `:rest_for_one`.
- `max_restarts::Int`: maximum number of restarts 
    allowed in a time frame, defaults to 3
- `max_seconds::Float64`: time frame in which 
    `max_restarts` applies, defaults to 5.
- `childs::Array{Child,1}`: supervised childs,
- `rtime::Array{Float64,1}`: last restart times.
"""
mutable struct Supervisor
    strategy::Symbol
    max_restarts::Int
    max_seconds::Float64
    childs::Array{Child,1}
    rtime::Array{Float64,1}

    Supervisor(strategy=:one_for_one, max_restarts=3, max_seconds=5) = 
        new(strategy, max_restarts, max_seconds, Child[], Float64[])
end

function restart_child(c::Child)
    if c.lk isa Link
        lk = spawn(c.start)
        c.lk.chn = lk.chn
        send(lk, Connect(Super(self())))
        update!(c.lk, c.lk, s=:self)
    else
        c.lk = Threads.@spawn c.start()
    end
end

function shutdown_child(c::Child)
    if c.lk isa Link
        try
            send(c.lk, Connect(self(), remove=true))
            exit!(c.lk, :shutdown)
        catch
        end
    end
end

function must_restart(c::Child, reason)
    return isnothing(c.start) ? false :
        c.restart == :permanent ? true :
        c.restart == :temporary ? false :
        isnormal(reason) ? false : true
end

function restart_limit!(s::Supervisor)
    length(s.rtime) > s.max_restarts && popfirst!(s.rtime)
    push!(s.rtime, time_ns()/1e9)
    return length(s.rtime) > s.max_restarts &&
        s.rtime[end]-s.rtime[begin] ≤ s.max_seconds
end

function restart(s::Supervisor, c::Child)
    if s.strategy == :one_for_one
        warn("supervisor: restarting")
        restart_child(c)
    elseif s.strategy == :one_for_all
        warn("supervisor: restarting all")
        for child in s.childs
            child.lk != c.lk && shutdown_child(child)
            restart_child(child)
        end
    else
        warn("supervisor: restarting rest")
        ix = findfirst(x->x.lk==c.lk, s.childs)
        for child in s.childs[ix:end] 
            child.lk != c.lk && shutdown_child(child)
            restart_child(child)
        end
    end
end

# 
# Supervisor behavior methods
#
function (s::Supervisor)(msg::Exit)
    ix = findfirst(c->c.lk==msg.from, s.childs)
    isnothing(ix) && throw(AssertionError("child not found"))
    if must_restart(s.childs[ix], msg.reason)
        if restart_limit!(s)
            warn("supervisor: restart limit $(s.max_restarts) exceeded!")
            send(self(), Exit(:shutdown, fill(nothing, 3)...))
        else
            restart(s, s.childs[ix])
        end
    else
        act = task_local_storage("_ACT")
        filter!(c->c.lk!=msg.from, act.conn)
        filter!(c->c.lk!=msg.from, s.childs)
    end
end
function (s::Supervisor)(child::Child)
    act = task_local_storage("_ACT")
    ix = findfirst(c->child.lk==c.lk, s.childs)
    isnothing(ix) && push!(s.childs, child)
    ix = findfirst(c->child.lk==c.lk, act.conn)
    isnothing(ix) && push!(act.conn, child)
    child.lk isa Link && send(child.lk, Connect(Super(act.self)))
end
function (s::Supervisor)(::Delete, lk)
    act = task_local_storage("_ACT")
    filter!(c->c.lk!=lk, act.conn)
    filter!(c->c.lk!=lk, s.childs)
    lk isa Link && trysend(lk, Connect(act.self, remove=true))
end
function (s::Supervisor)(::Terminate, lk::Link)
    s(Delete(), lk)
    try
        send(lk, Connect(self(), remove=true))
        exit!(lk, :shutdown)
    catch
    end
end
(s::Supervisor)(::Which) = s.childs

#
# API functions
#
"""
```
supervisor( strategy=:one_for_one, 
            max_restarts::Int=3, 
            max_seconds::Real=5; 
            name=nothing, kwargs...)
```
Start a supervisor actor with an empty child list and
return a link to it.

# Parameters
- `strategy=:one_for_one`: supervision strategy, can be 
    either `:one_for_one`, `:one_for_all` or `:rest_for_one`,
- `max_restarts::Int=3`: maximum number of restarts 
    allowed in a time frame,
- `max_seconds::Real=5`: time frame in which 
    `max_restarts` applies,
- `name=nothing`: name (Symbol) under which it should
    be registered,
- `kwargs...`: keyword arguments to [`spawn`](@ref).

!!! note
    See the manual chapter on error handling for
    explanations of strategy.
"""
function supervisor(strategy=:one_for_one, max_restarts::Int=3, max_seconds::Real=5; name=nothing, kwargs...)
    @assert strategy in strategies "Unknown strategy $strategy"
    lk = spawn(Supervisor(strategy, max_restarts, max_seconds); kwargs...)
    !isnothing(name) && register(name, lk)
    send(lk, Update(:mode, :supervisor))
    return lk
end

"""
    count_children(sv::Link)

Return a named tuple containing children counts for the given
supervisor `sv`.
"""
function count_children(sv::Link)
    childs = call(sv, Which())
    d = Dict(:all => length(childs))
    ms = [c.lk.mode for c in childs if c.lk isa Link]
    tasks = length(childs)- length(ms)
    for m in Set(ms)
        d[m] = length(filter(==(m), ms))
    end
    tasks > 0 &&  (d[:tasks] = tasks)
    (; d...)
end

"""
    delete_child(sv::Link, child)

Tell a supervisor `sv` to delete `child` (a `Link` or `Task`) from 
the childs list. 
"""
delete_child(sv::Link, child) = send(sv, Delete(), child)

"""
```
start_actor(start, sv::Link, restart::Symbol; kwargs...)
```
Tell a supervisor `sv` to start an actor, to add 
it to its childs list and to return a link to it.

# Parameters
- `start`: start behavior of the child, a callable object,
- `sv::Link`: link to a started supervisor,
- `restart::Symbol=:transient`: restart option, one of 
    `:permanent`, `:temporary`, `:transient`,
- `kwargs...`: keyword arguments to [`spawn`](@ref).

!!! note
    See the manual chapter on error handling for
    explanations of restart options.
"""
function start_actor(start, sv::Link, restart::Symbol=:transient; kwargs...)
    @assert restart in restarts "Not a known restart strategy: $restart"
    lk = spawn(start; kwargs...)
    send(sv, Child(lk, start, restart))
    return lk
end

function _supervisetask(t::Task, sv::Link; timeout::Real=5.0, pollint::Real=0.1)
    res = timedwait(()->t.state!=:runnable, timeout; pollint)
    res == :ok ?
        t.state == :done ?
            send(sv, Exit(:done, t, t, nothing)) :
            send(sv, Exit(t.exception, t, t, nothing)) :
        send(sv, Exit(res, t, t, nothing))
end

"""
```
start_task(start, sv::Link, restart::Symbol=:transient; 
           timeout::Real=5.0, pollint::Real=0.1)
```
Tell a supervisor `sv` to start a child task, to add 
it to its childs list and to return it.

# Parameters
- `start`: must be callable with no arguments,
- `sv::Link`: link to a started supervisor,
- `restart::Symbol=:transient`: restart option, one of 
    `:temporary`, `:transient`,
- `timeout::Real=5.0`: how many seconds should a task 
    be supervised, 
- `pollint::Real=0.1`: polling interval in seconds.

!!! note
    See the manual chapter on error handling for
    explanations of restart options.
"""
function start_task(start, sv::Link, restart::Symbol=:transient; 
                    timeout::Real=5.0, pollint::Real=0.1)
    @assert restart in (:temporary, :transient) "Not a known restart strategy: $restart"
    t = Threads.@spawn start()
    !isinf(timeout) && @async _supervisetask(t, self(); timeout, pollint)
    send(sv, Child(t, start, restart))
    return t
end

"""
    terminate_child(sv::Link, child::Link)

Tell a supervisor `sv` to remove a child `c` from its 
childs and to terminate it with reason `:shutdown`.
"""
terminate_child(sv::Link, child::Link) = call(sv, Terminate(), child)

"""
    which_children(sv::Link, info=false)

Tell a supervisor `sv` to return its childs list. If `info=true` 
it returns a list of named tuples with more child information.
"""
function which_children(sv::Link, info=false)
    function cinfo(c::Child)
        if c.lk isa Link
            i = Actors.info(c.lk)
            (actor=i.mode, bhv=i.bhvf, pid=i.pid, thrd=i.thrd, task=i.task, id=i.tid, restart=c.restart)
        else
            (task=c.lk, restart=c.restart)
        end
    end 
    childs = call(sv, Which())
    return info ? map(cinfo, childs) : childs
end

"""
```
supervise(sv::Link, start, restart::Symbol=:transient; 
          timeout::Real=5.0, pollint::Real=0.1)
```
Tell a supervisor `sv` to add the calling actor or
task to its childs list.

# Parameters
- `sv::Link`: link to a started supervisor,
- `start`: start behavior of the child, a callable object,
- `restart::Symbol=:transient`: restart option, one of 
    `:permanent`, `:temporary`, `:transient`,

!!! note
    See the manual chapter on error handling for
    explanations of restart options.
"""
function supervise(sv::Link, start, restart::Symbol=:transient; timeout::Real=5.0, pollint::Real=0.1)
    me = try
        self()
    catch
        current_task()
    end
    if me isa Link
        @assert restart in restarts "Not a known restart strategy: $restart"
    else
        @assert restart in (:temporary, :transient) "Not allowed for tasks: $restart"
        !isinf(timeout) && @async _supervisetask(me, sv; timeout, pollint)
    end
    send(sv, Child(me, start, restart))
end

"""
    unsupervise(sv::Link)

Tell a supervisor `sv` to delete the calling actor or task
from the childs list. 
"""
function unsupervise(sv::Link)
    me = try
        self()
    catch
        current_task()
    end
    send(sv, Delete(), me)
end
