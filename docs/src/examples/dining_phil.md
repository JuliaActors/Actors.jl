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
```

The first part of an actor based solution is that each chopstick between the philosophers is an actor. So only one access to a chopstick is possible at a time. And the philosophers will have to communicate with the chopsticks to take them:

```julia
mutable struct Chopstick
    idle::Bool
    Chopstick() = new(true)
end

function (c::Chopstick)(cust, ::Val{:take})
    if c.idle
        send(cust, self(), Val(:taken))
        c.idle = false
    else
        send(cust, self(), Val(:busy))
    end
end
(c::Chopstick)(::Val{:put}) = c.idle = true
```

We have modeled a chopstick actor as a functor with two messages, `:take` and `:put`.

Now the philosophers! We model them with behavior functions representing their state, the respective philosopher as an acquaintance and state transitions with `become`. So a philosopher is a finite state machine:

```julia
function thinking(p::Phil, ::Val{:eat})
    send(p.left, self(), Val(:take))
    send(p.right, self(), Val(:take))
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
```

The crucial step here in preventing a deadlock is that a philosopher puts down his chopstick if he is  `right_waiting` or `left_waiting` and gets a `:busy` or if he is `denied` and gets a `:taken` message. Then he switches again to `thinking` and sends a message to himself to `:eat`. So he can try again.

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
    delay(thinking_time, Val(:eat), p)
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
