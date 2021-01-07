#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#

#
# the following is needed for giving a warning from a thread. 
# see: https://github.com/JuliaLang/julia/issues/35689
# 
enable_finalizers(on::Bool) = ccall(:jl_gc_enable_finalizers, Cvoid, (Ptr{Cvoid}, Int32,), Core.getptls(), on)

# 
# those functions realize the Msg protocol
# this is the 2nd actor layer
#

# Become
onmessage(A::_ACT, msg::Become) = A.bhv = _current(msg.x)
function onmessage(A::_ACT, msg::Call)
    A.res = A.bhv(msg.x...)
    send(msg.from, Response(A.res, A.self))
end

# Cast
onmessage(A::_ACT, msg::Cast) = A.res = A.bhv(msg.x...)

# Diag
function onmessage(A::_ACT, msg::Diag)
    res = first(msg.x) == 9999 ? A :
        first(msg.x) == 99 ? errored() : :ok
    send(msg.from, Response(res, A.self))
end

# Connect
function onmessage(A::_ACT, msg::Connect)
    if !msg.remove
        push!(A.conn, msg.x)
        unique!(A.conn)
    else
        filter!(c->c.lk!=msg.x, A.conn)
    end
end

# Exec
onmessage(A::_ACT, msg::Exec) = send(msg.from, Response(_current(msg.func)(), A.self))
function onmessage(A::_ACT, msg::Init)
    A.init = _current(msg.x)
    A.sta  = A.init()
end

# Term
onmessage(A::_ACT, msg::Term) = A.term = _current(msg.x)
function onmessage(A::_ACT, msg::Query)
    msg.x in (:mode,:bhv,:res,:sta,:usr) ?
        send(msg.from, Response(getfield(A, msg.x), A.self)) :
        send(msg.from, Response("$(msg.x) not available", A.self))
end

# Update
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

# dispatch on Request or user defined Msg
onmessage(A::_ACT, msg::Msg) = A.res = A.bhv(msg)
