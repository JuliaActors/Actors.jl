#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#

#
# This implements Agha's example 3.2.1
#

using Actors, Printf
import Actors: spawn, newLink

mutable struct StackNode{T}
    content::T
    link::Link
end

struct Pop <: Msg
    customer::Link
end

struct Push{T} <: Msg
    content::T
end

struct Print <: Msg end

forward!(lk::L, msg::M) where {L<:Link, M<:Msg} = send!(lk, msg)

# ----- this is essentially Agha's code example written in Julia/YAActL
function stack_node(sn::StackNode, msg::Pop)
    isnothing(sn.content) || become(forward!, sn.link)
    send!(msg.customer, Response(sn.content))
end

function stack_node(sn::StackNode, msg::Push)
    P = spawn(Func(stack_node, sn))
    become(stack_node, StackNode(msg.content, P))
end

mystack = spawn(Func(stack_node, StackNode(nothing, newLink())))

response = newLink()

send!(mystack, Pop(response))  # new stack
receive!(response).y           # returns nothing
send!(mystack, Push(1))        # push 1 on the stack
send!(mystack, Pop(response))  # pop it
receive!(response).y           # returns 1, 1st node now forwards messages
send!(mystack, Pop(response)); # pop again
receive!(response).y           # now returns nothing

for i ∈ 1:5
    send!(mystack, Push(i))
end

# (send!(mystack, Print()); sleep(0.1))

for i ∈ 1:5
    send!(mystack, Pop(response))
    println(receive!(response).y)
end
