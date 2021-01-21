# Producer-Consumer Problem

This [classic problem](https://en.wikipedia.org/wiki/Producer–consumer_problem) describes producers and consumers sharing a buffer with a given capacity. A producer produces an item at a time, puts it into the buffer and starts again. At the same time consumers are consuming the items (i.e. removing them from the buffer). The problem ist to make sure that a producer won't add items to the buffer if it is full and that a consumer won't try to remove them from an empty buffer. 

The solution for a producer is to go to sleep if the buffer is full. The next time, a consumer removes an item from the buffer, the buffer notifies the stalled producer, who then starts to replenish the buffer again. In the same way, the consumer can go to waiting if it finds the buffer empty. The next time a producer delivers an item, the buffer notifies the waiting consumer.

We implement this problem with three kinds of actors for store, producer and consumer.

The store has a fixed capacity, holds items and queues of stalled producers and waiting customers and a counting variable.

```julia
# examples/prod_cons.jl

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

We implement the store's behavior as a function object receiving two messages `Put()` and `Take()`.

```julia
@msg Put Full Done Ok Take Empty Notify

function (s::Store)(::Put, prod, item)
    if isfull(s)
        send(prod, Full(), item)
        push!(s.prod, prod)
    elseif s.count < maxitems
        push!(s.items, item)
        s.count += 1
        s.count == maxitems ?
            send(prod, Done()) :
            send(prod, Ok(), item)
        !isempty(s.cons) && send(popfirst!(s.cons), Notify())
    else
        send(prod, Done())
    end
end
function (s::Store)(::Take, cons)
    if isempty(s)
        send(cons, Empty())
        push!(s.cons, cons)
    else
        send(cons, popfirst!(s.items))
        !isempty(s.prod) && send(popfirst!(s.prod), Notify())
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

Those are acquaintances of their behavior functions. We have also a print server actor `prn` as a global variable.

```julia
function prod_start(p::Prod, start)
    become(producing, p)
    send(self(), start+1)
    send(prn, "producer $(p.name) started")
end
function producing(p::Prod, item)
    sleep(rand())
    send(p.store, Put(), self(), item)
end
function producing(p::Prod, ::Ok, item)
    send(prn, "producer $(p.name) delivered item $item")
    send(self(), item+1)
end
function producing(p::Prod, ::Full, item)
    send(prn, "producer $(p.name) stalled with item $item")
    become(stalled, p, item)
end
function producing(p::Prod, ::Done)
    send(prn, "producer $(p.name) done")
    stop()
end
function stalled(p::Prod, item, ::Notify)
    send(p.store, Put(), self(), item)
    become(producing, p)
end

function cons_start(c::Cons)
    become(buying, c)
    send(c.store, Take(), self())
    send(prn, "consumer $(c.name) started")
end
function buying(c::Cons, item)
    become(consuming)
    send(self(), c)
    send(prn, "consumer $(c.name) got item $item")
end
function buying(c::Cons, ::Empty)
    become(waiting, c)
    send(prn, "consumer $(c.name) found store empty")
end
function consuming(c)
    sleep(rand())
    become(buying, c)
    send(c.store, Take(), self())
end
function waiting(c::Cons, ::Notify)
    become(buying, c)
    send(c.store, Take(), self())
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
julia> include("examples/prod_cons.jl")

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

We had limited the sold items to 10. This is a queueing process.
