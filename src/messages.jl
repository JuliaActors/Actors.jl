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
    Diag(from::Link)

A synchronous [`Msg`](@ref) to an actor to send a 
`Response` message with its internal `_ACT` variable to `from`.
"""
struct Diag <: Msg 
    from::Link
end

"""
    Exit(reason, stack)

A [`Msg`](@ref) causing an actor to stop with an exit
`code`. If present, it calls its [`term!`](@ref) function with
`code` as last argument.
"""
struct Exit{T,U} <: Msg 
    reason::T
    stack::U
end
Exit() = Exit(:ok, nothing)

"""
    Timeout()

A return value to signal that a timeout has occurred.
"""
struct Timeout <: Msg end

"""
    Update(s::Symbol, x)

An asynchronous [`Msg`](@ref) to an actor to update its 
internal state `s` to `x`.

- `s::Symbol` can be one of `:arg`, `:self`, `:usr`.
"""
struct Update <: Msg
    s::Symbol
    x
end
