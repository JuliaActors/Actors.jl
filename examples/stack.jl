#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#

#
# This implements Agha's example 3.2.1
#

using Actors
import Actors: spawn, newLink

mutable struct StackNode{T,L}
    content::T
    link::L
end

struct Pop{L}
    customer::L
end

struct Push{T}
    content::T
end

forwarder = send

function (sn::StackNode)(msg::Pop)
    isnothing(sn.content) || become(forwarder, sn.link)
    send(msg.customer, Response(sn.content))
end
(sn::StackNode)(msg::Push) = become(StackNode(msg.content, spawn(sn)))

mystack = spawn(StackNode(nothing, newLink()))
response = newLink()

for i ∈ 1:5
    send(mystack, Push(i))
end

for i ∈ 1:5
    send(mystack, Pop(response))
    println(receive(response).y)
end
