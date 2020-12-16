#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#

using Actors
import Actors: spawn, spawnf

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

function (c::Chopstick)(cust, ::Val{:take})
    if c.idle
        send(cust, (self(), Val(:taken)))
        c.idle = false
    else
        send(cust, (self(), Val(:busy)))
    end
end
(c::Chopstick)(::Val{:put}) = c.idle = true

function thinking(p::Phil, ::Val{:eat})
    send(p.left, (self(), Val(:take)))
    send(p.right, (self(), Val(:take)))
    become(hungry, p)
end
function hungry(p::Phil, chop, ::Val{:taken})
    chop == p.left ?
        become(right_waiting, p) :
        become(left_waiting,  p)
end
hungry(p::Phil, chop, ::Val{:busy}) = become(denied, p)
function denied(p::Phil, other, ::Val{:taken})
    send(other, Val(:put))
    become(thinking, p)
    send(self(), Val(:eat))
end
function denied(p::Phil, chop, ::Val{:busy})
    become(thinking, p)
    send(self(), Val(:eat))
end
function right_waiting(p::Phil, chop, ::Val{:taken})
    if chop == p.right 
        become(eating, p)
        p.eaten += te = randn()+eating_time
        delay(te, Val(:think), self())
    end
end
function right_waiting(p::Phil, chop, ::Val{:busy})
    send(p.left, Val(:put))
    become(thinking, p)
    send(self(), Val(:eat))
end
function left_waiting(p::Phil, chop, ::Val{:taken})
    if chop == p.left
        become(eating, p)
        p.eaten += te = randn()+eating_time
        delay(te, Val(:think), self())
    end
end
function left_waiting(p::Phil, chop, ::Val{:busy})
    send(p.right, Val(:put))
    become(thinking, p)
    send(self(), Val(:eat))
end
function eating(p::Phil, ::Val{:think})
    send(p.left, Val(:put))
    send(p.right, Val(:put))
    become(thinking, p)
    delay(randn()+thinking_time, Val(:eat), self())
end

eaten(phils...) = Tuple(round(Int, query(p, :bhv).a[1].eaten) for p in phils)

c1 = spawn(Chopstick())
c2 = spawn(Chopstick())
c3 = spawn(Chopstick())
c4 = spawn(Chopstick())
c5 = spawn(Chopstick())

descartes = spawnf(thinking, Phil(c1,c2,0.0))
nietzsche = spawnf(thinking, Phil(c2,c3,0.0))
kant      = spawnf(thinking, Phil(c3,c4,0.0))
hume      = spawnf(thinking, Phil(c4,c5,0.0))
plato     = spawnf(thinking, Phil(c5,c1,0.0))

for p in (descartes, nietzsche, kant, hume, plato)
    delay(thinking_time, Val(:eat), p)
end

for i in 1:5
    sleep(1)
    println(i, "s: ", eaten(descartes, nietzsche, kant, hume, plato))
end

for a in (descartes, nietzsche, kant, hume, plato, c1, c2, c3, c4, c5)
    exit!(a)
end
