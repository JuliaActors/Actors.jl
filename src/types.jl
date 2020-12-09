#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#

# -----------------------------------------------
# Basic Types
# -----------------------------------------------
"""
    Args(args...; kwargs...)

A structure for updating arguments to an actor's behavior.
"""
struct Args{A,B}
    args::A
    kwargs::B

    Args(args...; kwargs...) = new{typeof(args),typeof(kwargs)}(args, kwargs)
end

"""
    Bhv(func, a...; kw...)(c...)

A callable struct to represent actor behavior. It is executed
with parameters from the incoming communication.

# Parameters

- `f::Function`: a function,
- `a...`: stored acquaintance parameters to `f`,
- `kw...`: stored keyword arguments,
- `c...`: parameters from the incoming communication.
"""
struct Bhv
    f::Function
    a::Tuple
    kw::Base.Iterators.Pairs
    ϕ::Function

    Bhv(f, a...; kw...) =new(f, a, kw, (c)->f(a..., c...; kw...))
end
(p::Bhv)(c...) = p.ϕ(c)

#
# Since Bhv contains an anonymous function, the following 
# is needed to make it executable in another thread or worker.
# It returns a Bhv for the current world age.
# 
_current(p::Bhv) = Bhv(p.f, p.a...; p.kw...)

"""
```
Link{C} <: ActorInterfaces.Classic.Addr
Link(chn::C, pid::Int, type::Symbol) where C
```

A mailbox for communicating with actors. A concrete type of
this must be returned by an actor on creation with [`spawn`](@ref).

# Fields/Parameters
- `chn::C`: C can be any type and characterizes the interface
    to an actor,
- `pid::Int`: the pid (worker process identifier) of the actor, 
- `mode::Symbol`: a symbol characterizing the actor mode.
"""
mutable struct Link{C} <: Addr
    chn::C
    pid::Int
    mode::Symbol
end

"""
```
_ACT
```
Internal actor status variable.

# Fields

1. `mode::Symbol`: the actor mode,
2. `bhv::AbstractBehavior`: a partial function or a function object,
3. `init::Union{Nothing,Function}`: the init function and its arguments,
4. `term::Union{Nothing,Function}`: the terminate function and its arguments,
5. `self::Link`: the actor's address,
6. `name::Union{Nothing,Symbol}`: the actor's registered name.
7. `res::Any`: the result of the last behavior execution,
8. `sta::Any`: a variable for representing state,
9. `usr::Any`: user variable for plugging in something.

see also: [`Bhv`](@ref), [`Link`](@ref)
"""
mutable struct _ACT
    mode::Symbol
    bhv::Any
    init::Union{Nothing,Function}
    term::Union{Nothing,Function}
    self::Union{Nothing,Link}
    name::Union{Nothing,Symbol}
    res::Any
    sta::Any
    usr::Any
end

"""
    _ACT(mode=:default)

Return a actor variable `_ACT`.
"""
_ACT(mode=:default) = _ACT(mode, Bhv(+), fill(nothing, 7)...)

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
