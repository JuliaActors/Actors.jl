# Producer-Consumer Problem

The problem describes producers and consumers who share a store with a given capacity. The producers produce an item at a time, put it into the store and start again. At the same time the consumers are consuming the items (i.e. removing them from the store). The problem ist to make sure that the producer won't add items to the store if it is full and that the consumer won't try to remove them from an empty store. The solution for a producer is to go to sleep if the store is full. The next time a consumer removes an item from the store, the store notifies the stalled producer, who starts to replenish the store again. In the same way, the consumer can go to waiting if it finds the store empty. The next time a producer delivers an item, the store notifies the waiting consumer.

We implement this problem with three kinds of actors for the store, the producers and a consumer.

The store has a fixed capacity, holds the items and lists for stalled producers and waiting customers and a counting variable.

```julia
using Actors, Printf
import Actors: spawn

const maxitems = 10

mutable struct Store
    capacity::Int
    items::Array{Any,1}
    prod::Array{Link,1}
    cons::Array{Link,1}
    count::Int
    Store(capacity::Int) = new(capacity, Any[], Link[], Link[], 0)
end

available(s::Store) = 0 < length(s.items) < s.capacity
isfull(s::Store) = length(s.items) ≥ s.capacity
Base.isempty(s::Store) = isempty(s.items)
```

We implement the stores behavior as a functor receiving two messages `:put` and `:take`.

```julia
function (s::Store)(::Val{:put}, prod, item)
    if isfull(s)
        send(prod, Val(:full), item)
        push!(s.prod, prod)
    elseif s.count < maxitems
        push!(s.items, item)
        s.count += 1
        s.count == maxitems ?
            send(prod, Val(:done)) :
            send(prod, Val(:ok), item)
        !isempty(s.cons) && send(popfirst!(s.cons), Val(:notify))
    else
        send(prod, Val(:done))
    end
end
function (s::Store)(::Val{:take}, cons)
    if isempty(s)
        send(cons, Val(:empty))
        push!(s.cons, cons)
    else
        send(cons, popfirst!(s.items))
        !isempty(s.prod) && send(popfirst!(s.prod), Val(:notify))
    end
end
```

Producers and consumers have a name and a link to the store:

```julia
struct Prod
    name::String
    store::Link
end

struct Cons
    name::String
    store::Link
end
```

Those become acquaintances of their behavior functions. We have also a print server actor `prn` as a global variable.

```julia
function prod_start(p::Prod, start)
    become(producing, p)
    send(self(), start+1)
    send(prn, "producer $(p.name) started")
end
function producing(p::Prod, item)
    sleep(rand())
    send(p.store, Val(:put), self(), item)
end
function producing(p::Prod, ::Val{:ok}, item)
    send(prn, "producer $(p.name) delivered item $item")
    send(self(), item+1)
end
function producing(p::Prod, ::Val{:full}, item)
    send(prn, "producer $(p.name) stalled with item $item")
    become(stalled, p, item)
end
function producing(p::Prod, ::Val{:done})
    send(prn, "producer $(p.name) done")
    stop()
end
function stalled(p::Prod, item, ::Val{:notify})
    send(p.store, Val(:put), self(), item)
    become(producing, p)
end

function cons_start(c::Cons)
    become(buying, c)
    send(c.store, Val(:take), self())
    send(prn, "consumer $(c.name) started")
end
function buying(c::Cons, item)
    become(consuming)
    send(self(), c)
    send(prn, "consumer $(c.name) got item $item")
end
function buying(c::Cons, ::Val{:empty})
    become(waiting, c)
    send(prn, "consumer $(c.name) found store empty")
end
function consuming(c)
    sleep(rand())
    become(buying, c)
    send(c.store, Val(:take), self())
end
function waiting(c::Cons, ::Val{:notify})
    become(buying, c)
    send(c.store, Val(:take), self())
end
```

Finally we start the simulation with a print server, a store, three producers and two consumers.

```julia
prn = spawn(s->print(@sprintf("%s\n", s)))
st = spawn(Store(5))
pr1 = spawn(prod_start, Prod("A", st), 100)
pr2 = spawn(prod_start, Prod("B", st), 200)
pr3 = spawn(prod_start, Prod("C", st), 300)
cs1 = spawn(cons_start, Cons("U", st))
cs2 = spawn(cons_start, Cons("V", st))

foreach(x->send(x), (pr1,pr2,pr3,cs1,cs2))
```

Let's see, what happens:

```julia
julia> include("examples/prodcons.jl")

julia> producer A started
consumer U started
producer C started
producer B started
consumer V started
consumer V found store empty
consumer U found store empty
producer A delivered item 101
consumer U got item 101
producer B delivered item 201
consumer V got item 201
producer C delivered item 301
consumer V got item 301
consumer U found store empty
producer C delivered item 302
consumer U got item 302
producer B delivered item 202
producer C delivered item 303
producer B delivered item 203
producer A delivered item 102
producer A delivered item 103
consumer U got item 202
consumer V got item 303
producer A done
consumer V got item 203
producer C done
producer B done
consumer V got item 102
consumer U got item 103
consumer V got item 104
consumer U found store empty
consumer V found store empty
```

We had limited the items to 10. This is a queueing process.
