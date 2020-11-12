#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#

# -----------------------------------------------
# Basic Types
# -----------------------------------------------
"""
    Func(f, args...; kwargs...)

A structure for passing a function `f` and its arguments
to an actor.
"""
struct Func{X,Y,Z}
    f::X
    args::Y
    kwargs::Z

    Func(f::F, args...; kwargs...) where F<:Function =
        new{typeof(f),typeof(args),typeof(kwargs)}(f, args, kwargs)
end

"""
    Link{C}(chn::C, pid::Int, type::Symbol)

A mailbox for communicating with actors. A concrete type of
this must be returned by an actor on creation with [`spawn`](@ref).

# Fields/Parameters
- `chn::C`: C can be any type and characterizes the interface
    to an actor,
- `pid::Int`: the pid of the actor, 
- `type::Symbol`: an arbitrary symbol characterizing the actor.
"""
struct Link{C}
    chn::C
    pid::Int
    type::Symbol
end

# -----------------------------------------------
# Message types
# -----------------------------------------------
"Abstract type for messages to actors."
abstract type Msg end

"""
    Response(y, from::Link=self())

A [`Msg`](@ref) representing a response to requests.

# Fields
- `y`: response content,
- `from::Link`: sender link.
"""
struct Response <: Msg
    y
    from::Link
end
Response(y) = Response(y, self())

# -----------------------------------------------
# Function primitives
# -----------------------------------------------
"""
```
spawn(bhv::Func; pid=myid(), thrd=false, sticky=false)
spawn(m::Val(:Actors), args...; kwargs...)
spawn(m::Module, args...; kwargs...)
```

Start a function `bhv` as an actor and return a [`Link`](@ref)
to it.
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
An application can extend this by further methods or use 
it to plugin the `Actors.jl` API.
"""
onmessage  # see actor.jl
