#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#

_terminate!(A::_ACT, reason) = !isnothing(A.term) && A.term.f((A.term.args..., reason)...; kwargs...)

#
# default dispatch ignores the mode argument
# such a user can implement methods such as
# onmessage(A::_ACT, ::Val{:mymode}, msg::Call)
#
onmessage(A::_ACT, mode, msg) = onmessage(A, msg) 
onmessage(A::_ACT, msg::Become) = A.bhv = msg.x
function onmessage(A::_ACT, mode, msg::Call)
    A.res = A.bhv.f((A.bhv.args..., msg.x...)...; A.bhv.kwargs...)
    send!(msg.from, Response(A.res, A.self))
end
onmessage(A::_ACT, msg::Cast) = (A.res = A.bhv.f((A.bhv.args..., msg.x...)...; A.bhv.kwargs...))
onmessage(A::_ACT, msg::Diag) = send!(msg.from, Response(msg.x == 0 ? :ok : A, A.self))
onmessage(A::_ACT, msg::Exec) = send!(msg.from, Response(msg.func.f(msg.func.args...; msg.func.kwargs...), A.self))
onmessage(A::_ACT, msg::Exit) = _terminate!(A, msg.reason)
function onmessage(A::_ACT, msg::Init)
    A.init = msg.x
    A.sta  = A.init.f(A.init.args...; A.init.kwargs...)
end
function onmessage(A::_ACT, msg::Query)
    msg.x in (:mode,:bhv,:res,:sta,:usr) ?
        send!(msg.from, Response(getfield(A, msg.x), A.self)) :
        send!(msg.from, Response("$(msg.x) not available", A.self))
end
function onmessage(A::_ACT, msg::Update)
    if msg.s in (:mode,:name,:self,:sta,:usr)
        setfield!(A, msg.s, msg.x)
    elseif msg.s == :arg
        A.bhv = Func(A.bhv.f, msg.x.args...;
            pairs((; merge(A.bhv.kwargs, msg.x.kwargs)...))...)
    else
        nothing
    end
end
# dispatch on Request or user defined Msg
function onmessage(A::_ACT, msg::Msg)
    A.res = A.bhv.f((A.bhv.args..., msg)...; A.bhv.kwargs...)
end
# default dispatch on Any 
function onmessage(A::_ACT, msg) 
    A.res = A.bhv.f((A.bhv.args..., msg...)...; A.bhv.kwargs...)
end

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
        onmessage(A, A.mode, msg)
        msg isa Exit && break
    end
    # isnothing(A.name) || call!(_REG, unregister, A.name)
end


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
    else
        lk = Link(RemoteChannel(()->Channel(_act, 32), pid),
                  pid, :remote)
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
