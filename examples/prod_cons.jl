#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#

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

struct Prod
    name::String
    store::Link
end

struct Cons
    name::String
    store::Link
end

@msg Put Full Done Ok Take Empty Notify

available(s::Store) = 0 < length(s.items) < s.capacity
isfull(s::Store) = length(s.items) ≥ s.capacity
Base.isempty(s::Store) = isempty(s.items)

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

prn = spawn(s->print(@sprintf("%s\n", s)))
st = spawn(Store(5))
pr1 = spawn(prod_start, Prod("A", st), 100)
pr2 = spawn(prod_start, Prod("B", st), 200)
pr3 = spawn(prod_start, Prod("C", st), 300)
cs1 = spawn(cons_start, Cons("U", st))
cs2 = spawn(cons_start, Cons("V", st))

foreach(x->send(x), (pr1,pr2,pr3,cs1,cs2))
