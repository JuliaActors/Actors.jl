#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#

send!(lk::Link, msg::Msg) = put!(lk.chn, msg)
send!(lk::Link, msg...) = put!(lk.chn, msg)

_match(msg::Msg, ::Nothing, ::Nothing) = true
_match(msg::Msg, M::Type{<:Msg}, ::Nothing) = msg isa M
_match(msg::Msg, ::Nothing, from::Link) =
    :from in fieldnames(typeof(msg)) ? msg.from == from : false
function _match(msg::Msg, M::Type{<:Msg}, from::Link)
    if :from in fieldnames(typeof(msg))
        return msg isa M && msg.from == from
    else
        return false
    end
end

"""
```
receive!(lk; timeout=5.0)
receive!(lk, from; timeout=5.0)
receive!(lk, M; timeout=5.0)
receive!(lk, M, from; timeout=5.0)
```
Receive a message over a link `lk`.

If `M` or `from` are provided, `receive!` returns only a 
matching message. Other messages in `lk` are restored to it in their
previous order.

# Parameters
- `lk::Link`: local or remote link over which the message is received,
- `M::Type{<:Msg}`: [`Msg`](@ref) type,
- `from::Link`: local or remote link of sender. If `from` is
    provided, only messages with a `from` field can be matched.
- `timeout::Real=5.0`: maximum waiting time in seconds.
    - If `timeout==0`, `lk` is scanned only for existing messages.
    - Set `timeout=Inf` if you don't want to timeout. 

# Returns
- received message or `Timeout()`.
"""
receive!(lk::L; kwargs...) where L<:Link = receive!(lk, nothing, nothing; kwargs...)
receive!(lk::L, from::Link; kwargs...) where L<:Link = receive!(lk, nothing, from; kwargs...)
receive!(lk::L, M::Type{<:Msg}; kwargs...) where L<:Link = receive!(lk, M, nothing; kwargs...)
function receive!(lk::L1, M::MT, from::L2; 
    timeout::Real=5.0) where {L1<:Link,MT<:Union{Nothing,Type{<:Msg}},L2<:Union{Nothing,Link}}

    done = [false]
    msg = Timeout()
    stash = Msg[]
    ev = Base.Event()
    timeout > 0 && !isinf(timeout) && Timer(x->notify(ev), timeout)

    @async begin
        while !done[1]
            timeout == 0 && !isready(lk.chn) && break
            _match(fetch(lk.chn), M, from) && break
            done[1] || push!(stash, take!(lk.chn))
        end
        notify(ev)
    end

    wait(ev)
    done[1] = true
    isready(lk.chn) && (msg = take!(lk.chn))
    while !isempty(stash) && isready(lk.chn)
        push!(stash, take!(lk.chn))
    end
    foreach(x->put!(lk.chn, x), stash)
    return msg
end

"""
```
request!(lk::Link, msg::Msg; full=false, timeout::Real=5.0)
request!(lk::Link, M::Type{<:Msg}, args...; kwargs...)
```
Send a message to an actor, block, receive and return the result.

# Arguments
- `lk::Link`: actor link, or `name::Symbol` (if registered),
- `msg::Msg`: a message,
- `Msg::Type{<:Msg}`: a message type,
- `args...`: optional arguments to `Msg`, 
- `full`: if `true` return the full [`Response`](@ref) message.
- `timeout::Real=5.0`: timeout in seconds after which a 
    [`Timeout`](@ref) is returned,
- `kwargs...`: `full` or `timeout`.

"""
function request!(lk::L, msg::Msg; 
                full=false, timeout::Real=5.0) where L<:Link
    send!(lk, msg)
    resp = receive!(msg.from, timeout=timeout)
    return resp isa Timeout || full ? resp : resp.y
end
function request!(lk::L, M::Type{<:Msg}, args...; kwargs...)  where L<:Link
    me = lk isa Link{Channel} ?
            Link(1) : 
            Link(RemoteChannel(()->Channel(1)), myid(), :remote)
    request!(lk, isempty(args) ? M(me) : M(args, me); kwargs...)
end
request!(lk::L, args...; kwargs...) where L<:Link = request!(lk, Call, args...; kwargs...)
