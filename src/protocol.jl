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
onmessage(A::_ACT, msg::Diag) = send(msg.from, Response(first(msg.x) == 0 ? :ok : A, A.self))
onmessage(A::_ACT, msg::Exec) = send(msg.from, Response(_current(msg.func)(), A.self))
onmessage(A::_ACT, msg::Exit) = _terminate!(A, msg.reason)
function onmessage(A::_ACT, msg::Init)
    A.init = _current(msg.x)
    A.sta  = A.init()
end
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
        A.bhv = Func(A.bhv.f, msg.x.args...;
            pairs((; merge(A.bhv.kw, msg.x.kwargs)...))...)
    end
end
# dispatch on Request or user defined Msg
onmessage(A::_ACT, msg::Msg) = A.res = A.bhv(msg)
