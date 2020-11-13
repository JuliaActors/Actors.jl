#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#

# -----------------------------------------------
# Interface primitives
# -----------------------------------------------
"""
```
spawn(bhv::Func; pid=myid(), thrd=false, sticky=false, taskref=nothing)
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
- `m::Module`: the `Module` implementing `spawn`.
"""
spawn   # see actor.jl

"""
    send!(lk::Link, msg)

Send a message to an actor.
"""
send!   # see com.jl

"""
    become!(lk::Link, bhv::Func)

Tell an actor `lk` to assume the behavior function `bhv`.
"""
become!  # see actor.jl

"""
    become(bhv::Function, args...; kwargs...)

Cause your actor to take on a new behavior. This can only be
called from inside an actor/behavior.

# Arguments
- `bhv::Function`: function implementing the new behavior,
- `args...`: arguments to `bhv` (without `msg`),
- `kwargs...`: keyword arguments to `bhv`.
"""
become   # see actor.jl

"""
    self()

Get the [`Link`](@ref) of your actor.
"""
self    # see actor.jl

"""
    onmessage(A::_ACT, msg)

An actor executes this function when a message arrives.
An application can extend this by further methods and use 
it to plugin the `Actors.jl` API.
"""
onmessage  # see actor.jl
