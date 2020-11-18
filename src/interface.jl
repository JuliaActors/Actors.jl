#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#

# -----------------------------------------------
# Interface primitives
# 
#     Other actor libraries sharing actors with
#     Actors.jl must reimplement newLink, spawn
#     and send! with their own concrete Link type.
# -----------------------------------------------

"""
    newLink(size=32; remote=false)

Create a local Link with a buffered `Channel` `size ≥ 1`.

# Parameters
- `size=32`: the size of the channel buffer,
- `remote=false`: should a remote link be created,
- `pid=myid()`: optional pid of the remote worker.
"""
newLink

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

# -----------------------------------------------
# API primitives
#
#       Other actor libraries wanting to use the
#       Actors.jl API must execute onmessage with
#       an _ACT variable and the received message.
# -----------------------------------------------

"""
    onmessage(A::_ACT, msg)

An actor executes this function when a message arrives.
An application can extend this by further methods and must
use it to plugin the `Actors.jl` API.
"""
onmessage  # see actor.jl
