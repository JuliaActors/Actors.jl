#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#

# 
# those functions realize the Msg protocol
# this is the 2nd actor layer
#
onmessage(A::_ACT, msg::Become) = A.bhv = _current(msg.x)
function onmessage(A::_ACT, msg::Call)
    A.res = A.bhv(msg.x...)
    send(msg.from, Response(A.res, A.self))
end
onmessage(A::_ACT, msg::Cast) = A.res = A.bhv(msg.x...)
function onmessage(A::_ACT, msg::Diag)
    res = first(msg.x) == 9999 ? A :
        first(msg.x) == 99 ? errored() : :ok
    send(msg.from, Response(res, A.self))
end
onmessage(A::_ACT, msg::Exec) = send(msg.from, Response(_current(msg.func)(), A.self))
function onmessage(A::_ACT, msg::Init)
    A.init = _current(msg.x)
    A.sta  = A.init()
end
onmessage(A::_ACT, msg::Term) = A.term = _current(msg.x)
function onmessage(A::_ACT, msg::Query)
    msg.x in (:mode,:bhv,:res,:sta,:usr) ?
        send(msg.from, Response(getfield(A, msg.x), A.self)) :
        send(msg.from, Response("$(msg.x) not available", A.self))
end
function onmessage(A::_ACT, msg::Update)
    if msg.s in (:name,:self,:sta,:usr)
        setfield!(A, msg.s, msg.x)
    elseif msg.s == :mode
        A.mode = msg.x
        A.self.mode = msg.x
    elseif msg.s == :arg
        A.bhv = Bhv(A.bhv.f, msg.x.args...;
            pairs((; merge(A.bhv.kw, msg.x.kwargs)...))...)
    end
end
function onmessage(A::_ACT, msg::Connect)
    push!(A.conn, msg.x)
    unique!(A.conn)
end
function onmessage(A::_ACT, msg::Exit)
    for c in A.conn
        c.lk != msg.from && send(c.lk, Exit(self(), msg.reason, msg.link, msg.state))
    end
    _terminate!(A, msg.reason)
    throw(ActorExit(msg.reason))
end
function onmessage(A::_ACT, ::Val{:system}, msg::Exit)
    if msg.reason isa Exception
        saveerror(msg.link)
        @warn "Actor failure" exception=msg.reason
    end
    ix = findfirst(==(msg.from), A.conn)
    if !isnothing(ix)
        # eventually restart a child
        deleteat!(A.conn, ix)
    end
end
function onmessage(A::_ACT, msg::Stop)
    for c in A.conn
        c.lk != msg.from && send(c.lk, Exit(self(), msg.reason, nothing, nothing))
    end
    _terminate!(A, msg.reason)
end
# dispatch on Request or user defined Msg
onmessage(A::_ACT, msg::Msg) = A.res = A.bhv(msg)
