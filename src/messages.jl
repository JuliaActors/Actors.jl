#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#

# those are the internal messages

"""
    Become(x::Func)

An asynchronous [`Msg`](@ref) to an actor to change its 
behavior.
"""
struct Become <: Msg
    x::Func
end

"""
    Call(arg, from::Link)

A synchronous [`Msg`](@ref) to an actor to execute its 
behavior with `arg...` and to send the result as a [`Response`](@ref) 
message to `from`.
"""
struct Call <: Msg
    x
    from::Link
end
Call(from) = Call((),from)

"""
    Cast(arg)

An asynchronous [`Msg`](@ref) to an actor to execute 
its behavior with `arg...` without sending a response.

If the actor is set to `state` dispatch, it updates its internal 
state with the result. 
"""
struct Cast <: Msg
    x
end
Cast() = Cast(())

"""
    Diag(from::Link)

A synchronous [`Msg`](@ref) to an actor to send diagnostic
information.
"""
struct Diag <: Msg
    x
    from::Link
end

"""
    Exit(reason=:ok, stack)

A [`Msg`](@ref) causing an actor to stop with an exit
`code`. If present, it calls its [`term!`](@ref) function with
`code` as last argument.
"""
struct Exit{T,U} <: Msg 
    reason::T
    stack::U
end
Exit(reason=:ok) = Exit(reason, nothing)

"""
    Exec(func::Func, from::Link)

A synchronous [`Msg`](@ref) to an actor to execute `func`
and to send a `Response` message with the return value to `from`.
"""
struct Exec <: Msg
    func
    from::Link
end
Exec(t::Tuple, from::Link) = Exec(first(t), from)

"""
    Init(f::Func)

A [`Msg`](@ref) to an actor to execute the given
[`Func`](@ref) and to register it in the [`_ACT`](@ref)
variable.
"""
struct Init <: Msg
    x::Func
end

"""
    Query(s::Symbol, from::Link)

A [`Msg`](@ref) to an actor to send a 
`Response` message with one of its internal state 
variables `s` to `from`.

- `s::Symbol` can be one of `:sta`, `:res`, `:bhv`, `:dsp`.
"""
struct Query <: Msg
    x::Symbol
    from::Link
end
Query(t::Tuple, from::Link) = Query(first(t), from)

"""
    Term(x::Func)

A [`Msg`](@ref) to an actor to save the given [`Func`](@ref) 
and to execute it upon termination.
"""
struct Term <: Msg
    x::Func
end

"""
    Timeout()

A return value to signal that a timeout has occurred.
"""
struct Timeout <: Msg end

"""
    Update(s::Symbol, x)

An asynchronous [`Msg`](@ref) to an actor to update its 
internal state `s` to `x`.

- `s::Symbol` can be one of `:arg`, `:self`, `:sta`, `:usr`.
"""
struct Update <: Msg
    s::Symbol
    x
end
