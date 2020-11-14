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

"""
    _ACT()

Internal actor status variable.

# Fields

1. `bhv::Func` : the behavior function and its internal arguments,
2. `init::Func`: the init function and its arguments,
3. `term::Func`: the terminate function and its arguments,
4. `self::Link`: the actor's (local or remote) self,
5. `name::Symbol`: the actor's registered name.
6. `res::Any`: the result of the last behavior execution,
7. `usr::Any`: user variable for plugging in something.

see also: [`Func`](@ref), [`Link`](@ref)
"""
mutable struct _ACT
    bhv::Func
    init::Union{Nothing,Func}
    term::Union{Nothing,Func}
    self::Union{Nothing,Link}
    name::Union{Nothing,Symbol}
    res::Any
    usr::Any

    _ACT() = new(Func(+), fill(nothing, 6)...)
end

# -----------------------------------------------
# Message types
# -----------------------------------------------
"Abstract type for messages to actors."
abstract type Msg end

"""
    Request(x, from::Link)

A generic [`Msg`](@ref) for user requests.
"""
struct Request <: Msg
    x
    from::Link
end

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
