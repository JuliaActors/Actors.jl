#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#

# messages to the supervisor
struct ChildInit{L,I}
    from::L
    init::I
end
struct Delete end 
struct Terminate end
struct Which end
struct Strategy
    strategy::Symbol
end
struct NodeFailure{T} 
    pids::T
end

const strategies = (:one_for_one, :one_for_all, :rest_for_one)
const restarts   = (:permanent, :temporary, :transient)
const sv_options = (:strategy, :max_restarts, :max_seconds, :spares)

isnormal(reason) = reason in (:normal, :shutdown, :done, :timed_out)

"""
```
Supervisor(; strategy=:one_for_one, max_restarts=3, max_seconds=5, kwargs...)
```
Supervisor functor with data and behavior.

# Fields (acquaintances)
- `option::Dict{Symbol,Any}`: supervisor option
- `childs::Array{Child,1}`: supervised childs,
- `rtime::Array{Float64,1}`: last restart times.

# Options
- `strategy::Symbol`: supervision strategy, can be 
    either `:one_for_one`, `:one_for_all` or `:rest_for_one`.
- `max_restarts::Int`: maximum number of restarts allowed in a time frame,
- `max_seconds::Float64`: time frame in which `max_restarts` applies, defaults to 5,
- `kwargs...`: further option to extend supervisor behavior.
"""
struct Supervisor{O,C,T}
    option::O
    childs::C
    rtime::T
end
function Supervisor(; strategy=:one_for_one, max_restarts=3, max_seconds=5, kwargs...)
    s = Supervisor(Dict{Symbol,Any}(), Child[], Float64[])
    s.option[:strategy]     = strategy
    s.option[:max_restarts] = max_restarts
    s.option[:max_seconds]  = max_seconds
    merge!(s.option, kwargs)
    return s
end

function shutdown_child(c::Child)
    if c.lk isa Link
        try
            send(c.lk, Connect(self(), true))
            exit!(c.lk, :shutdown)
        catch exc
            log_error("shutdown_child", exc)
        end
    end
end

function restart_child!(c::Child, act::_ACT)
    if c.lk.chn isa RemoteChannel
        lk = !isnothing(c.start) ? c.start(act.bhv, pid=c.lk.pid) :
            !isnothing(act.init) ? spawn(act.init, pid=c.lk.pid) :
                spawn(act.bhv, pid=c.lk.pid)
    else
        lk = !isnothing(c.start) ? c.start(act.bhv) :
            !isnothing(act.init) ? spawn(act.init) :
                spawn(act.bhv)
    end
    c.lk.chn = lk.chn
    c.lk.pid = lk.pid
    send(lk, Connect(Super(self())))
    update!(lk, c.lk, s=:self)
end
function restart_child!(c::Child, ::Nothing)
    c.lk[] = Threads.@spawn c.start()
    _supervisetask(c.lk, self(), timeout=c.info.timeout, pollint=c.info.pollint)
end

function shutdown_restart_child!(c::Child)
    act = isnothing(c.start) ? diag(c.lk, :act) : nothing
    shutdown_child(c)
    restart_child!(c, act)
end

function must_restart(c::Child, reason)
    return c.info.restart == :permanent ? true :
        c.info.restart == :temporary ? false :
        isnormal(reason) ? false : true
end

function restart_limit!(s::Supervisor)
    length(s.rtime) > s.option[:max_restarts] && popfirst!(s.rtime)
    push!(s.rtime, time_ns() / 1e9)
    return length(s.rtime) > s.option[:max_restarts] &&
        s.rtime[end] - s.rtime[begin] ≤ s.option[:max_seconds]
end

function restart!(s::Supervisor, c::Child, msg::Exit)
    if s.option[:strategy] == :one_for_one
        log_warn("supervisor: restarting")
        restart_child!(c, msg.state)
    elseif s.option[:strategy] == :one_for_all
        log_warn("supervisor: restarting all")
        for child in s.childs
            child.lk == c.lk ? 
                restart_child!(child, msg.state) :
                shutdown_restart_child!(child)
        end
    else
        log_warn("supervisor: restarting rest")
        ix = findfirst(x -> x.lk == c.lk, s.childs)
        for child in s.childs[ix:end] 
            child.lk == c.lk ? 
                restart_child!(child, msg.state) :
                shutdown_restart_child!(child)
        end
    end
end

# 
# Supervisor behavior methods
#
function (s::Supervisor)(msg::ChildInit)
    ix = findfirst(c -> c.lk == msg.from, s.childs)
    isnothing(ix) && throw(AssertionError("child not found"))
    s.childs[ix].init = msg.init
end
function (s::Supervisor)(msg::Exit)
    ix = findfirst(c -> c.lk == msg.from, s.childs)
    isnothing(ix) && throw(AssertionError("child not found"))
    if must_restart(s.childs[ix], msg.reason)
        if restart_limit!(s)
            log_warn("supervisor: restart limit $(s.option[:max_restarts]) exceeded!")
            send(self(), Exit(:shutdown, fill(nothing, 3)...))
        else
            restart!(s, s.childs[ix], msg)
        end
    else
        ## todo: warn about temporary actor failure!
        act = task_local_storage("_ACT")
        filter!(c -> c.lk != msg.from, act.conn)
        filter!(c -> c.lk != msg.from, s.childs)
    end
end
function (s::Supervisor)(child::Child)
    act = task_local_storage("_ACT")
    ix = findfirst(c -> child.lk == c.lk, s.childs)
    isnothing(ix) && push!(s.childs, child)
    ix = findfirst(c -> child.lk == c.lk, act.conn)
    isnothing(ix) && push!(act.conn, child)
    if child.lk isa Link 
        send(child.lk, Connect(Super(act.self)))
        myid() == child.lk.pid || rnfd_add(s, child.lk)
    end
end
function (s::Supervisor)(::Delete, lst)
    lk = lst isa Symbol ? whereis(lst) : lst
    act = task_local_storage("_ACT")
    filter!(c -> c.lk != lk, act.conn)
    filter!(c -> c.lk != lk, s.childs)
    if lk isa Link 
        trysend(lk, Connect(act.self, true))
        lk.pid ≠ myid() &&  send(rnfd(s), Remove(lk))
    end
end
function (s::Supervisor)(::Terminate, ls)
    lk = ls isa Symbol ? whereis(ls) : ls
    s(Delete(), lk)
    try
        send(lk, Connect(self(), true))
        exit!(lk, :shutdown)
    catch
    end
end
(s::Supervisor)(::Which) = s.childs
(s::Supervisor)(msg::Strategy) = s.option[:strategy] = msg.strategy

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
Spawn a supervisor actor with an empty child list and
return a link to it.

# Arguments
The following arguments are mandatory and go into a supervisor's 
options:
- `strategy=:one_for_one`: [supervision strategy](@ref strategies), can be 
    either `:one_for_one`, `:one_for_all` or `:rest_for_one`,
- `max_restarts::Int=3`: maximum number of restarts 
    allowed in a time frame,
- `max_seconds::Real=5`: time frame in which 
    `max_restarts` applies,

# Keyword arguments and further options
- `name=nothing`: name (Symbol) under which a supervisor should
    be registered, if `nothing` it doesn't get registered,
- `kwargs...`: further keyword arguments to the 
    [`Supervisor`](@ref) and to [`spawn`](@ref). Keyword arguments 
    not taken by `spawn` are supervisor options, used to extend a 
    supervisor's functionality.

# Reserved options
- `strategy`, `max_restarts`, `max_seconds`, `name` are reserved, 
    see above,
- `spares=[5,6,7]`: spare `pid`s, where you can give spare pids 
    (e.g. `[5,6,7]`) to a supervisor used for actor restarts after 
    node failures.
"""
function supervisor(strategy=:one_for_one, max_restarts::Int=3, max_seconds::Real=5; name=nothing, kwargs...)
    @assert strategy in strategies "Unknown strategy $strategy"
    sv_kw = merge((; strategy, max_restarts, max_seconds), structdiff(NamedTuple(kwargs), NamedTuple{spawn_kws}))
    lk = spawn(Supervisor(; sv_kw...); structdiff(NamedTuple(kwargs), sv_kw)...)
    !isnothing(name) && register(name, lk)
    send(lk, Update(:mode, :supervisor))
    return lk
end

"""
    count_children(sv)

Return a named tuple containing children counts for the given
supervisor `sv` (link or registered name).
"""
function count_children(sv)
    childs = call(sv, Which())
    d = Dict(:all => length(childs))
    ms = [c.lk.mode for c in childs if c.lk isa Link]
    tasks = length(childs) - length(ms)
    for m in Set(ms)
        d[m] = length(filter(==(m), ms))
    end
    tasks > 0 &&  (d[:tasks] = tasks)
    (; d...)
end

"""
```
start_actor(start, sv, cb=nothing, restart::Symbol=:transient; 
            name::Union{Symbol,Nothing}=nothing, kwargs...)
```
Tell a supervisor `sv` to start an actor, to add 
it to its childs list and to return a link to it.

# Arguments
- `start`: start behavior of the child, a callable object,
- `sv::Link`: link to a started supervisor,
- `cb=nothing`: callback (a callable object, gets the last
    actor behavior as argument and must return a [`Link`](@ref));  
    if `nothing`, the actor gets restarted with its [`init!`](@ref) 
    callback or with its last behavior,
- `restart::Symbol=:transient`: [restart option](@ref restart), one of 
    `:permanent`, `:temporary`, `:transient`,
- `name::Union{Symbol,Nothing}=nothing`, name (Symbol) under which
    the actor should be registered,
- `kwargs...`: keyword arguments to [`spawn`](@ref).
"""
function start_actor(start, sv::Link, cb=nothing, restart::Symbol=:transient; 
    name::Union{Symbol,Nothing}=nothing, kwargs...)
    @assert restart in restarts "Not a known restart strategy: $restart"
    lk = spawn(start; kwargs...)
    isnothing(name) || register(name, lk)
    send(sv, Child(lk, cb, lk.chn isa RemoteChannel ? start : nothing, name, (; restart)))
    return lk
end

function _supervisetask(r::Ref{Task}, sv; timeout::Real=5.0, pollint::Real=0.1)
    res = timedwait(() -> r[].state != :runnable, timeout; pollint)
    res == :ok ?
        r[].state == :done ?
            send(sv, Exit(:done, r, r[], nothing)) :
            send(sv, Exit(r[].exception, r, r[], nothing)) :
        send(sv, Exit(res, r, r[], nothing))
end

"""
```
start_task(start, sv, cb=nothing; 
           timeout::Real=5.0, pollint::Real=0.1)
```
Spawn a task with a `start` behavior and tell the supervisor `sv` to supervise it (with
restart strategy `:transient`) and return a reference to it.

# Parameters
- `start`: must be a callable object (with no arguments),
- `sv`: link or registered name of a supervisor,
- `cb=nothing`: callback for restart (a callable object, must 
    return a `Task`); if `cb=nothing`, the task gets restarted 
    with its `start` function,
- `timeout::Real=5.0`: how long [seconds] should the task 
    be supervised, 
- `pollint::Real=0.1`: polling interval [seconds].
"""
function start_task(start, sv, cb=nothing; timeout::Real=5.0, pollint::Real=0.1)
    r = Ref(Threads.@spawn start())
    !isinf(timeout) && @async _supervisetask(r, sv; timeout, pollint)
    send(sv, Child(r, isnothing(cb) ? start : cb, start, nothing, (; restart=:transient, timeout, pollint)))
    return r
end

"""
    terminate_child(sv, ls)

Tell a supervisor `sv` to remove a child `ls` from its 
childs list and to terminate it with reason `:shutdown`.

# Arguments
- `sv`: link or registered name of a supervisor,
- `ls`: link or registered name of a child.
"""
terminate_child(sv, ls) = call(sv, Terminate(), ls)

"""
    which_children(sv, info=false)

Tell a supervisor `sv` to return its childs list. 

# Arguments
- `sv`: link or registered name of a supervisor,
- `info=false`: If `info=true`, return a list of named tuples 
    with child information.
"""
function which_children(sv, info=false)
    function cinfo(c::Child)
        if c.lk isa Link
            i = Actors.info(c.lk)
            (actor = i.mode, bhv = i.bhvf, pid = i.pid, thrd = i.thrd, task = i.task, id = i.tid, name = i.name, restart = c.info.restart)
        else
            (task = c.lk[], restart = c.info.restart)
        end
    end 
    childs = call(sv, Which())
    return info ? map(cinfo, childs) : childs
end

"""
```
supervise(sv, child=self(); cb=nothing, restart::Symbol=:transient)
```
Tell a supervisor `sv` to supervise the given `child` actor.

# Arguments
- `sv`: link or registered name of a supervisor,
- `child`: link or registered name of an actor to supervise.

# Keyword Arguments
- `cb=nothing`: callback (a callable object), takes the 
    previous actor behavior as argument and must return 
    a [`Link`](@ref) to a new actor; if `nothing`, the
    actor gets restarted with its [`init!`](@ref) callback 
    or its previous behavior. 
- `restart::Symbol=:transient`: [restart option](@ref restart), one of 
    `:permanent`, `:temporary`, `:transient`,
"""
function supervise(sv, child=self(); cb=nothing, restart::Symbol=:transient)
    @assert restart in restarts "Not a known restart strategy: $restart"
    act = try
        a = task_local_storage("_ACT")
        a.self == child ? a : diag(child, :act)
    catch
        diag(child, :act)
    end
    send(sv, Child(child isa Symbol ? whereis(child) : child, cb, isnothing(act.init) ? act.bhv : act.init, act.name, (; restart)))
end

"""
    unsupervise(sv, lst=self())

Tell a supervisor `sv` to delete `ls` from its childs list. 

# Arguments
- `sv`: link or registered name of a supervisor,
- `lst`: link, registered name of an actor or task.
"""
unsupervise(sv, lst=self()) = send(sv, Delete(), lst)

"""
    set_strategy(sv, strategy::Symbol)

Tell a supervisor `sv` to change its restart `strategy`.
"""
function set_strategy(sv, strategy::Symbol) 
    @assert strategy in strategies "$strategy not known!"
    send(sv, Strategy(strategy))
end
