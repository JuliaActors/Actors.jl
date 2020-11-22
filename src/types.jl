#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#

# -----------------------------------------------
# Basic Types
# -----------------------------------------------
"""
    Func(func, args...; kwargs...)

A structure to represent an actor behavior.

# Parameters

- `func`: a callable object (function, functor ...),
- `args...`: arguments to `func`. Those can be no, partial
    or full arguments. Eventually missing arguments must be
    sent with a message in order to execute `func` with all
    needed arguments.
- `kwargs...`: keyword arguments.
"""
struct Func
    f
    args::Tuple
    kwargs::Base.Iterators.Pairs

    Func(f, args...; kwargs...) =new(f, args, kwargs)
end

"""
    Link{C}(chn::C, pid::Int, type::Symbol)

A mailbox for communicating with actors. A concrete type of
this must be returned by an actor on creation with [`spawn`](@ref).

# Fields/Parameters
- `chn::C`: C can be any type and characterizes the interface
    to an actor,
- `pid::Int`: the pid of the actor, 
- `mode::Symbol`: a symbol characterizing the actor mode.
"""
mutable struct Link{C} <: Addr
    chn::C
    pid::Int
    mode::Symbol
end

"""
```
_ACT{T} <: Actor{T}
```
Internal actor status variable.

# Fields

1. `mode::Symbol`: the actor mode,
2. `bhv::T` : the behavior function and its internal arguments,
3. `init::T`: the init function and its arguments,
4. `term::T`: the terminate function and its arguments,
5. `self::Addr`: the actor's (local or remote) self,
6. `name::Symbol`: the actor's registered name.
7. `res::Any`: the result of the last behavior execution,
8. `sta::Any`: a variable for representing state,
9. `usr::Any`: user variable for plugging in something.

see also: [`Func`](@ref), [`Link`](@ref)
"""
mutable struct _ACT{T} <: Actor{T}
    mode::Symbol
    bhv::T
    init::Union{Nothing,T}
    term::Union{Nothing,T}
    self::Union{Nothing,Link}
    name::Union{Nothing,Symbol}
    res::Any
    sta::Any
    usr::Any
end

"""
    _ACT(mode=:default)

Return a actor variable `_ACT{Func}`.
"""
_ACT(mode=:default) = _ACT(mode, Func(+), fill(nothing, 7)...)

# -----------------------------------------------
# Public message types
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
