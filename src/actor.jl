#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#

#
# The onmessage protocol is executed by an actor on an
# arriving message. It has several layers:
#
# 1st layer: (default) dispatch on Any
#
"""
    onmessage(bhv, msg)

Default behavior function to execute the current actor 
behavior `bhv` with the message `msg`. The actor calls
`bhv(msg)` when a message arrives. 

# Parameters
- `bhv`: excutable object (closure or functor) taking
    parameters `msg`,
- `msg`: message parameters to `bhv`.
"""
onmessage(bhv, msg) = Base.invokelatest(bhv, msg...)
onmessage(bhv::Bhv, msg) = bhv(msg...)

"""
```
onmessage(A::_ACT, msg)
onmessage(A::_ACT, mode, msg)
```
An actor executes this function when a message arrives.

Actor libraries or applications can use this to

- plugin the `Actors.jl` API (first form) or
- extend it to other protocols by using the 2nd form.
"""
onmessage(A::_ACT, msg) = (A.res = onmessage(A.bhv, msg))

# 
# 2nd layer: dispatch on msg::Msg (see protocol.jl)
#

#
# 3rd layer: dispatch on mode
#
# This allows other libraries to implement methods
# such as onmessage(A::_ACT, ::Val{:mymode}, msg::Call).
# If no such methods are implemented, it defaults to the
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
        if isempty(A.conn)
            onmessage(A, Val(A.mode), msg)
        else
            try
                onmessage(A, Val(A.mode), msg)
            catch exc
                onerror(A, exc)
                isnothing(A.name) || call(_REG, unregister, A.name)
                rethrow()
            end
        end
        msg isa Exit && !_sticky(A) && break
    end
    isnothing(A.name) || call(_REG, unregister, A.name)
end

"""
```
spawn(f, args...; 
      pid=myid(), thrd=false, sticky=false, 
      taskref=nothing, remote=false, mode=:default)
```

Create an actor with a behavior `f(args...)` and return 
a [`Link`](@ref) to it.

# Parameters

- `f`: callable object (function, closure or functor)
    to execute when a message arrives,
- `args...`: (partial) arguments to it,
- `pid=myid()`: pid of worker process the actor should be started on,
- `thrd=false`: thread number the actor should be started on or `false`,
- `sticky=false`: if `true` the actor is started on the current thread,
- `taskref=nothing`: if a `Ref{Task}()` is given here, it gets the started `Task`,
- `remote=false`: if true, a remote channel is created,
- `mode=:default`: mode, the actor should operate in.

**Note:** If you need keyword arguments `kwargs...` to 
`f`, you can do `spawn(Bhv(f, args...; kwargs...))`.
"""
function Classic.spawn( f, args...; pid=myid(), thrd=false, 
                        sticky=false, taskref=nothing, 
                        remote=false, mode=:default)
    isempty(args) || (f = Bhv(f, args...))
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
        remote && (lk = _rlink(lk))
    else
        lk = Link(RemoteChannel(()->Channel(_act, 32), pid),
                  pid, mode)
        f = _rlink(f)
    end
    put!(lk.chn, Update(:self, lk))
    mode == :default || put!(lk.chn, Update(:mode, mode))
    become!(lk, f)
    return lk
end

"""
    self()

Get the [`Link`](@ref) of your actor.
"""
Classic.self() = task_local_storage("_ACT").self
# 
# Note: a reference to the actor's status variable must be
#       available as task_local_storage("_ACT") for this to 
#       work.
# 

"""
```
become(func, args...; kwargs...)
```

Cause your actor to take on a new behavior. This can only be
called from inside an actor/behavior.

# Arguments
- `func`: a callable object,
- `args...`: (partial) arguments to `func`,
- `kwargs...`: keyword arguments to `func`.
"""
function Classic.become(func, args...; kwargs...)
    isempty(args) && isempty(kwargs) ?
        task_local_storage("_ACT").bhv = func :
        become(Bhv(func, args...; kwargs...))
end
# 
# Note: a reference to the actor's status variable must be
#       available as task_local_storage("_ACT") for this to 
#       work.
# 

"""
    stop(reason=:normal)

Cause your actor to stop with a `reason`.
"""
stop(reason=:normal) = send!(self(), Exit(reason, fill(nothing, 3...)))
