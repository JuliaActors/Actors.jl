#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#

# those are the internal messages

"""
    Become(bhv)

An asynchronous [`Msg`](@ref) to an actor to change its 
behavior to `bhv`.
"""
struct Become <: Msg
    x
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
    Connect(x, remove=false)

A [`Msg`](@ref) to an actor to connect with `x`. If 
`remove=true`, an existing connection gets removed.
"""
struct Connect <: Msg
    x
    remove::Bool
end
Connect(x) = Connect(x, false)

"""
    Diag(x, from::Link)

A synchronous [`Msg`](@ref) to an actor to send diagnostic
information.
"""
struct Diag <: Msg
    x
    from::Link
end

"""
    Down(from, reason, task)

A [`Msg`](@ref) to a monitor actor indicating that an error
has occurred or a [`Exit`](@ref) has been received.
"""
struct Down{T,U} <: Msg
    from::Union{Link,Task}
    reason::T
    task::U
end

"""
    Exec(func::Bhv, from::Link)

A synchronous [`Msg`](@ref) to an actor to execute `func`
and to send a `Response` message with the return value to `from`.
"""
struct Exec <: Msg
    func
    from::Link
end
Exec(t::Tuple, from::Link) = Exec(first(t), from)

"""
    Exit(reason, from, task, state)

A [`Msg`](@ref) to an actor causing it to terminate. 
`Exit` messages are sent to [`connect`](@ref)ed actors 
if an error has occurred and then are propagated further.
They are not propagated by `:sticky` actors, see 
[`trapExit`](@ref).
"""
struct Exit{T,U,V} <: Msg
    reason::T
    from
    task::U
    state::V
end

"""
    Init(f::Bhv)

A [`Msg`](@ref) to an actor to execute the given
[`Bhv`](@ref) and to store it in the [`_ACT`](@ref)
variable.
"""
struct Init <: Msg
    x::Bhv
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
    Term(x::Bhv)

A [`Msg`](@ref) to an actor to save the given [`Bhv`](@ref) 
and to execute it upon termination.
"""
struct Term <: Msg
    x::Bhv
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
