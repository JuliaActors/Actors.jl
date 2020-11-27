#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#

using Actors, Test

struct MyMsg <: Msg 
    x::Int
end

struct MySource <: Msg
    x::Int
    from::Link
end

function writeLk(lk::Link, src=true, slp=false)
    for i in 1:4
        put!(lk.chn, MyMsg(i))
        yield()
        slp && sleep(rand()*0.1)
    end
    if src
        put!(lk.chn, MySource(10, lk2))
        yield()
        slp && sleep(rand()*0.1)
    end
    for i in 5:8
        put!(lk.chn, MyMsg(i))
        yield()
        slp && sleep(rand()*0.1)
    end
end

function readLk(lk::Link)
    buf = Int[]
    while isready(lk.chn)
        push!(buf, take!(lk.chn).x)
    end
    buf
end

lk1 = Actors.newLink()
lk2 = Actors.newLink()

@test Actors._match(MyMsg(1), nothing, nothing)
@test Actors._match(MySource(1,lk2), nothing, nothing)

@test Actors._match(MyMsg(1), MyMsg, nothing)
@test !Actors._match(MyMsg(1), Response, nothing)

@test !Actors._match(MyMsg(1), nothing, lk2)
@test Actors._match(MySource(1,lk2), nothing, lk2)
@test !Actors._match(MySource(1,lk2), nothing, lk1)

@test !Actors._match(MyMsg(1), MyMsg, lk2)
@test !Actors._match(MySource(1,lk2), MyMsg, lk2)
@test Actors._match(MySource(1,lk2), MySource, lk2)
@test !Actors._match(MySource(1,lk2), MySource, lk1)

writeLk(lk1)
@test length(lk1.chn.data) == 9
msg = receive(lk1, MySource, lk2)
@test msg == MySource(10, lk2)
@test length(lk1.chn.data) == 8
@test readLk(lk1) == collect(1:8)
@test length(lk1.chn.data) == 0

msg = receive(lk1, MySource, lk2, timeout=1)
@test msg == Actors.Timeout()

writeLk(lk1, false)
@test length(lk1.chn.data) == 8
msg = receive(lk1, MySource, lk2, timeout=0)
@test msg == Actors.Timeout()
@test length(lk1.chn.data) == 8
@test readLk(lk1) == collect(1:8)
@test length(lk1.chn.data) == 0

@async writeLk(lk1, true, true)
msg = receive(lk1, MySource, lk2)
@test msg == MySource(10, lk2)
sleep(1)
@test length(lk1.chn.data) == 8
@test readLk(lk1) == collect(1:8)
@test length(lk1.chn.data) == 0

comtest(msg::MySource) = nothing
function comtest(msg::Request)
    res = (1, (2), (3,4,5), [6,7,8])
    if msg.x in 1:4
        send(msg.from, Response(res[msg.x], self()))
    else
        send(msg.from, Response("test", self()))
    end
    return nothing
end

A = Actors.spawn(Func(comtest))
send(A, MySource(1, lk2))
msg = receive(lk2, timeout=1)
@test msg == Actors.Timeout()
send(A, Request(10, lk2))
msg = receive(lk2, timeout=1)
@test msg == Response("test", A)

res = request(A, MySource(1, lk2), timeout=1)
@test res == Actors.Timeout()
res = request(A, Request(1, lk2), full=true, timeout=1)
@test res == Response(1, A)
@test request(A, Request(1, lk2), timeout=1) == 1
@test request(A, Request(2, lk2), timeout=1) == 2
@test request(A, Request(3, lk2), timeout=1) == (3,4,5)
@test request(A, Request(4, lk2), timeout=1) == [6,7,8]
@test request(A, Request(99, lk2), timeout=1) == "test"
