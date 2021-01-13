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
struct Supervisor
    strategy::Symbol
    max_restarts::Int
    max_seconds::Float64
    childs::Array{Child,1}
    rtime::Array{Float64,1}

    Supervisor(strategy=:one_for_one, max_restarts=3, max_seconds=5) = 
        new(strategy, max_restarts, max_seconds, Child[], Float64[])
end

function restart_child(c::Child)
    lk = spawn(c.start)
    c.lk.chn = lk.chn
end

function shutdown_child(c::Child)
    exit!(c.lk, :shutdown)
end

function restart(s::Supervisor, c::Child, reason::Symbol)
    start = c.restart == :permanent ? true :
        c.restart == :temporary ? false :
            reason in (:normal, :shutdown) ? false : true
    if start && !isnothing(c.start)
        length(s.rtime) ≥ s.max_restarts && popfirst!(s.rtime)
        push!(s.rtime, time_ns()/1e9)
        if length(s.rtime) ≥ s.max_restarts &&
            s.rtime[end]-s.rtime[begin] ≤ s.max_seconds
            send(self(), Exit(:shutdown, fill(nothing, 3)...))
        else
            if s.strategy == :one_for_one
                restart_child(c)
            elseif s.strategy == :one_for_all
                for child in s.childs
                    child != c && shutdown_child(child)
                    restart_child(child)
                end
            else
                ix = findfirst(==(c), s.childs)
                for child in s.childs[ix:end] 
                    child != c && shutdown_child(child)
                    restart_child(child)
                end
            end
        end
    end
end

# 
# Supervisor behavior methods
#
function (s::Supervisor)(msg::Exit)
    ix = findfirst(c->c.lk==msg.from, s.childs)
    restart(s, s.childs[ix], msg.reason)
end
function (s::Supervisor)(child::Child)
    act = task_local_storage("_ACT")
    push!(s.childs, child)
    push!(act.conn, child)
    send(child.lk, Connect(Super(act.self)))
end
function (s::Supervisor)(::Delete, lk::Link)
    act = task_local_storage("_ACT")
    filter!(c->c.lk!=lk, act.conn)
    filter!(c->c.lk!=lk, s.childs)
    send(lk, Connect(act.self, remove=true))
end
function (s::Supervisor)(::Terminate, lk::Link)
    s(Delete(), lk)
    exit!(lk, :shutdown)
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
"""
function supervisor(strategy=:one_for_one, max_restarts::Int=3, max_seconds::Real=5; name=nothing, kwargs...)
    @assert strategy in strategies "Unknown strategy: $strategy"
    lk = spawn(Supervisor(strategy, max_restarts, max_seconds); kwargs...)
    !isnothing(name) && register(name, lk)
    send(lk, Update(:mode, :sv))
    return lk
end

"""
    count_children(sv::Link)

Return a named tuple containing counts for the given
supervisor `sv`.
"""
function count_children(sv::Link)
    childs = call(sv, Which())
end

"""
    delete_child(sv::Link, c::Link)

Tell a supervisor `sv` to delete `c` from the childs list. 
"""
delete_child(sv::Link, c::Link) = send(sv, Delete(), c)

"""
```
start_child(sv::Link, start, restart::Symbol; kwargs...)
```
Tell a supervisor `sv` to start a child actor, to add 
it to its childs list and to return a link to it.

# Parameters
- `sv::Link`: link to a started supervisor,
- `start`: start behavior of the child, a callable object,
- `restart::Symbol=:transient`: restart option, one of 
    `:permanent`, `:temporary`, `:transient`,
- `kwargs...`: keyword arguments to [`spawn`](@ref).
"""
function start_child(sv::Link, start, restart::Symbol=:transient; kwargs...)
    @assert restart in restarts "Not a known restart strategy: $restart"
    lk = spawn(start; kwargs...)
    send(sv, Child(lk, start, restart))
    return lk
end

"""
    terminate_child(sv::Link, c::Link)

Tell a supervisor `sv` to remove a child `c` from its 
childs and to terminate it with reason `:shutdown`.
"""
terminate_child(sv::Link, c::Link) = call(sv, Terminate(), c)

"""
    which_children(sv::Link)

Tell a supervisor `sv` to return its childs list.
"""
which_children(sv::Link) = call(sv, Which())

"""
```
supervise(sv::Link, start, restart::Symbol=:transient; 
          timeout::Real=5.0, pollint::Real=0.1)
```
Tell a supervisor `sv` to add the calling actor to 
its childs list.

# Parameters
- `sv::Link`: link to a started supervisor,
- `start`: start behavior of the child, a callable object,
- `restart::Symbol=:transient`: restart option, one of 
    `:permanent`, `:temporary`, `:transient`,
"""
function supervise(sv::Link, start, restart::Symbol=:transient; timeout::Real=5.0, pollint::Real=0.1)
    @assert restart in restarts "Not a known restart strategy: $restart"
    send(sv, Child(self(), start, restart))
end

"""
    unsupervise(sv::Link)

Tell a supervisor `sv` to delete the calling actor 
from the childs list. 
"""
unsupervise(sv::Link) = delete_child(self())
