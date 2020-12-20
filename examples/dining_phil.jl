#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#

using Actors
import Actors: spawn

const eating_time = 5
const thinking_time = 10
const speedup = 100

mutable struct Phil{L}
    left::L
    right::L
    eaten::Float64
end

mutable struct Chopstick
    idle::Bool
    Chopstick() = new(true)
end

delay(time, msg, cust) = async() do 
    sleep(time/speedup)
    send(cust, msg)
end

@msg Take Taken Busy Put Eat Think

function (c::Chopstick)(cust, ::Take)
    if c.idle
        send(cust, self(), Taken())
        c.idle = false
    else
        send(cust, self(), Busy())
    end
end
(c::Chopstick)(::Put) = c.idle = true

function thinking(p::Phil, ::Eat)
    send(p.left, self(), Take())
    send(p.right, self(), Take())
    become(hungry, p)
end
function hungry(p::Phil, chop, ::Taken)
    chop == p.left ?
        become(right_waiting, p) :
        become(left_waiting,  p)
end
hungry(p::Phil, chop, ::Busy) = become(denied, p)
function denied(p::Phil, other, ::Taken)
    send(other, Put())
    become(thinking, p)
    send(self(), Eat())
end
function denied(p::Phil, chop, ::Busy)
    become(thinking, p)
    send(self(), Eat())
end
function right_waiting(p::Phil, chop, ::Taken)
    if chop == p.right 
        become(eating, p)
        p.eaten += te = randn()+eating_time
        delay(te, Think(), self())
    end
end
function right_waiting(p::Phil, chop, ::Busy)
    send(p.left, Put())
    become(thinking, p)
    send(self(), Eat())
end
function left_waiting(p::Phil, chop, ::Taken)
    if chop == p.left
        become(eating, p)
        p.eaten += te = randn()+eating_time
        delay(te, Think(), self())
    end
end
function left_waiting(p::Phil, chop, ::Busy)
    send(p.right, Put())
    become(thinking, p)
    send(self(), Eat())
end
function eating(p::Phil, ::Think)
    send(p.left, Put())
    send(p.right, Put())
    become(thinking, p)
    delay(randn()+thinking_time, Eat(), self())
end

eaten(phils...) = Tuple(round(Int, query(p, :bhv).a[1].eaten) for p in phils)

c1 = spawn(Chopstick())
c2 = spawn(Chopstick())
c3 = spawn(Chopstick())
c4 = spawn(Chopstick())
c5 = spawn(Chopstick())

descartes = spawn(thinking, Phil(c1,c2,0.0))
nietzsche = spawn(thinking, Phil(c2,c3,0.0))
kant      = spawn(thinking, Phil(c3,c4,0.0))
hume      = spawn(thinking, Phil(c4,c5,0.0))
plato     = spawn(thinking, Phil(c5,c1,0.0))

for p in (descartes, nietzsche, kant, hume, plato)
    delay(thinking_time, Eat(), p)
end

for i in 1:5
    sleep(1)
    println(i, "s: ", eaten(descartes, nietzsche, kant, hume, plato))
end

for a in (descartes, nietzsche, kant, hume, plato, c1, c2, c3, c4, c5)
    exit!(a)
end
