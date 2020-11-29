#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#

_terminate!(A::_ACT, reason) = !isnothing(A.term) && A.term.f((A.term.args..., reason)...; kwargs...)

#
# default dispatch on Any, this is the 1st actor layer 
# analog to the classical Actor Model
# 
"""
    onmessage(A::_ACT, msg)

An actor executes this function when a message arrives.
An application can extend this by further methods and must
use it to plugin the `Actors.jl` API.
"""
onmessage(A::_ACT, msg) = (A.res = A.bhv(msg...))

# 
# the 2nd actor layer is realized by the Msg protocol 
# (see protocol.jl) and enables the API
#

#
# the 3rd actor layer is bound to the mode argument.
# This enables 3rd libraries to implement methods such as
# onmessage(A::_ACT, ::Val{:mymode}, msg::Call)
# If no such methods are implemented it defaults to the
# 1st and 2nd layer.
#
onmessage(A::_ACT, mode, msg) = onmessage(A, msg) 

#
# this is the actor loop
#
# Note: when an actor task starts, it must put its _ACT
#       status variable into the task local storage.
#
function _act(ch::Channel)
    A = _ACT()
    task_local_storage("_ACT", A)
    while true
        msg = take!(ch)
        onmessage(A, Val(A.mode), msg)
        msg isa Exit && break
    end
    isnothing(A.name) || call(_REG, unregister, A.name)
end

"""
```
spawn(bhv::Func; pid=myid(), thrd=false, sticky=false, taskref=nothing, mode=:default)
spawn(m::Val(:Actors), args...; kwargs...)
spawn(m::Module, args...; kwargs...)
```

Start a function `bhv` as an actor and return a [`Link`](@ref)
to it.

# Parameters

- `bhv::Func`: behavior function,
- `pid=myid()`: pid of worker process the actor should be started on,
- `thrd=false`: thread number the actor should be started on or `false`,
- `sticky=false`: if `true` the actor is started on the current thread,
- `taskref=nothing`: if a `Ref{Task}()` is given here, it gets the started `Task`,
- `mode=:default`: mode, the actor should operate in.
"""
function spawn(bhv::Func; pid=myid(), thrd=false, sticky=false, taskref=nothing, mode=:default)
    if pid == myid()
        lk = newLink(32)
        if thrd > 0 && thrd in 1:nthreads()
            @threads for i in 1:nthreads()
                if i == thrd 
                    t = @async _act(lk.chn)
                    isnothing(taskref) || (taskref[] = t)
                    bind(lk.chn, t)
                end
            end
        else
            t = Task(()->_act(lk.chn))
            isnothing(taskref) || (taskref[] = t)
            pid == 1 && (t.sticky = sticky)
            bind(lk.chn, t)
            schedule(t)
        end
        lk.mode = mode
    else
        lk = Link(RemoteChannel(()->Channel(_act, 32), pid),
                  pid, mode)
    end
    put!(lk.chn, Update(:self, lk))
    mode == :default || put!(lk.chn, Update(:mode, mode))
    become!(lk, bhv)
    return lk
end

"""
    self()

Get the [`Link`](@ref) of your actor.
"""
self() = task_local_storage("_ACT").self
# 
# Note: a reference to the actor's status variable must be
#       available as task_local_storage("_ACT") for this to 
#       work.
# 

"""
```
become(bhv::Func)
become(func, args...; kwargs...)
```

Cause your actor to take on a new behavior. This can only be
called from inside an actor/behavior.

# Arguments
- `bhv::Func`: [`Func`](@ref) implementing the new behavior,
- `func`: callable object,
- `args1...`: (partial) arguments to `func`,
- `kwargs...`: keyword arguments to `func`.
"""
function become(bhv::Func)
    act = task_local_storage("_ACT")
    act.bhv = bhv
end
become(func, args...; kwargs...) = become(Func(func, args...; kwargs...))
# 
# Note: a reference to the actor's status variable must be
#       available as task_local_storage("_ACT") for this to 
#       work.
# 


"""
    stop(reason::Symbol)

Cause your actor to stop with a `reason`.
"""
stop(reason::Symbol=:ok) = send!(self(), Exit(reason))
