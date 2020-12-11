#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#

function _send!(chn::Channel, msg)
    Base.check_channel_state(chn)
    # reimplements Base.put_buffered with a modification
    lock(chn)
    try
        while length(chn.data) ≥ chn.sz_max  # modification: allow buffer overflow
            Base.check_channel_state(chn)
            wait(chn.cond_put)
        end
        push!(chn.data, msg)
        # notify all, since some of the waiters may be on a "fetch" call.
        notify(chn.cond_take, nothing, true, false)
    finally
        unlock(chn)
    end
    return msg
end
function _send!(rch::RemoteChannel, msg)
    if rch.where != myid() 
        # change any local links in msg to remote links
        msg = msg isa Msg ?
            typeof(msg)((_rlink(getfield(msg,i)) for i in fieldnames(typeof(msg)))...) :
            _rlink(msg)
    end
    put!(rch, msg)
end

"""
    send(lk::Link, msg)
Send a message to an actor.
"""
Classic.send(lk::Link, msg::Msg) = _send!(lk.chn, msg)
Classic.send(lk::Link, msg...) = _send!(lk.chn, msg)
Classic.send(name::Symbol, msg...) = _send!(whereis(name).chn, msg...)

_match(msg, ::Nothing, ::Nothing) = true
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
receive(lk; timeout=5.0)
receive(lk, from; timeout=5.0)
receive(lk, M; timeout=5.0)
receive(lk, M, from; timeout=5.0)
```
Receive a message over a link `lk`.

If `M` or `from` are provided, `receive` returns only a 
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
receive(lk::L; kwargs...) where L<:Link = receive(lk, nothing, nothing; kwargs...)
receive(lk::L, from::Link; kwargs...) where L<:Link = receive(lk, nothing, from; kwargs...)
receive(lk::L, M::Type{<:Msg}; kwargs...) where L<:Link = receive(lk, M, nothing; kwargs...)
function receive(lk::L1, M::MT, from::L2; 
    timeout::Real=5.0) where {L1<:Link,MT<:Union{Nothing,Type{<:Msg}},L2<:Union{Nothing,Link}}

    done = [false]
    fetched = [false]
    msg = Timeout()
    stash = Msg[]
    ev = Base.Event()
    timeout > 0 && !isinf(timeout) && Timer(x->notify(ev), timeout)

    @async begin
        while !done[1]
            fetched[1] = false
            timeout == 0 && !isready(lk.chn) && break
            if _match(fetch(lk.chn), M, from)
                fetched[1] = true
                break
            end
            done[1] || push!(stash, take!(lk.chn))
        end
        notify(ev)
    end

    wait(ev)
    done[1] = true
    fetched[1] && (msg = take!(lk.chn))
    while !isempty(stash) && isready(lk.chn)
        push!(stash, take!(lk.chn))
    end
    foreach(x->put!(lk.chn, x), stash)
    return applicable(length, msg) ?
        length(msg) == 1 ? first(msg) : msg : msg
end

"""
```
request(lk::Link, msg::Msg; full=false, timeout::Real=5.0)
request(lk::Link, M::Type{<:Msg}, args...; kwargs...)
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
function request(lk::Link, msg::Msg; full=false, timeout::Real=5.0)
    send(lk, msg)
    resp = receive(msg.from, timeout=timeout)
    return resp isa Timeout || full ? resp : resp.y
end
function request(lk::Link, M::Type{<:Msg}, args...; kwargs...)
    me = lk isa Link{Channel{Any}} ?
            newLink(1) :
            newLink(1, remote=true)
    request(lk, isempty(args) ? M(me) : M(args, me); kwargs...)
end
request(lk::Link, args...; kwargs...) = request(lk, Call, args...; kwargs...)
request(name::Symbol, args...; kwargs...) = request(whereis(name), args...; kwargs...)
