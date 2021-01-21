# Dining Philosophers

This is a [classic problem](https://en.wikipedia.org/wiki/Dining_philosophers_problem) to illustrate challenges with concurrency. We will give here a solution based on Dale Schumacher's blogpost [^1]. First some initial definitions:

```julia
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

delay(time, msg, cust) = async() do 
    sleep(time/speedup)
    send(cust, msg)
end

@msg Take Taken Busy Put Eat Think
```

The first part of an actor based solution is that each chopstick between the philosophers is an actor. So only one access to a chopstick is possible at a time. And the philosophers will have to communicate with the chopsticks to take them:

```julia
mutable struct Chopstick
    idle::Bool
    Chopstick() = new(true)
end

function (c::Chopstick)(cust, ::Take)
    if c.idle
        send(cust, self(), Taken())
        c.idle = false
    else
        send(cust, self(), Busy())
    end
end
(c::Chopstick)(::Put) = c.idle = true
```

We have modeled a chopstick actor as a function object with two message arguments, `Take` and `Put`.

Now the philosophers! We model them with behavior functions representing their state, the respective philosopher as an acquaintance and state transitions with `become`. So a philosopher is modeled as a finite state machine:

```julia
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
```

The crucial step in preventing a deadlock is that a philosopher puts down his chopstick if he is  `right_waiting` or `left_waiting` and gets a `:busy` or if he is `denied` and gets a `:taken` message. Then he switches again to `thinking` and sends a message to himself to `:eat`. So he can try again.

We need a stats function for eating time and we setup everything:

```julia
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
```

To get some stats we print the eaten times every second:

```julia
julia > for i in 1:5
            sleep(1)
            println(i, "s: ", eaten(descartes, nietzsche, kant, hume, plato))
        end
1s: (24, 34, 32, 31, 31)
2s: (57, 70, 61, 62, 65)
3s: (86, 101, 89, 96, 100)
4s: (119, 129, 123, 124, 132)
5s: (151, 162, 155, 155, 162)
```

So they are happy thinking and eating asynchronously. Since we have a speedup of 100, we can conclude that in 500 time units our philosophers eat around 155 (much more than programmers). We stop the whole thing in order to prevent overconsumption:

```julia
julia > foreach(a->exit!(a), (descartes, nietzsche, kant, hume, plato, c1, c2, c3, c4, c5))
```

Actually Gul Agha proposed something else. He reasoned about to let philosophers talk to each other:

> An actor is free and able to figure out a deadlock situation by querying other actors as to their local state. ... While these philosophers may be "busy" eating or looking for a chopstick, they nevertheless accept communications sent to them. [^2]

We did not go this road in order to avoid philosophical debates about local state. But you can try for yourself.

[^1]: Dale Schumacher. It's Actors All The Way Down, 2010: ["Dining Philosophers" in Humus](http://www.dalnefre.com/wp/2010/08/dining-philosophers-in-humus/)
[^2]: Gul Agha, 1986. Actors: A Model of Concurrent Computation in Distributed Systems, MIT,- p. 95
