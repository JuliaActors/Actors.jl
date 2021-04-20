# [Implement a Stack](@id stack)

As an illustration of actor behavior we reproduce Gul Agha's example 3.2.1:

> We implement a stack as a collection of actors with uniform behavior. ... [A] linked list consists of a collection of nodes each of which stores a value and knows the mail address of the "next" actor in the chain. ... Two kinds of operations may be requested of a *stack-node*: a *push* or a *pop*. In the first case, the new content to be pushed must be given, and in the second, the customer to which the value stored in the *stack-node* can be sent. [^1]

Let's first define some types:

```julia
mutable struct StackNode{T,L}  # a stack node object
    content::T
    link::L
end

struct Pop{L}                  # a pop message
    customer::L
end

struct Push{T}                 # a push message
    content::T
end
```

> The top of the stack is the only receptionist in the stack system and was the only actor of the stack system created externally. It is created with a NIL content which is assumed to be the bottom of the stack marker. Notice that no mail address of a stack node is ever communicated by any node to an external actor. Therefore no actor outside the configuration defined above can effect any of the actors inside the stack except by sending the receptionist a communication. When a *pop* operation is done, the actor on top of the stack simply becomes a *forwarder* to the next actor in the link. This means that all communications received by the top of the stack are now forwarded to the next element. [^1]

To implement the stack we use both the functional and the object oriented style for [actor behaviors](../manual/behaviors.md):

- `forwarder` is just an alias for `send` which we put together with `sn.link` into a behavior. After `become(forwarder, sn.link)` the actor will forward any received message to `sn.link`.
- `StackNode` is a function object with two methods for `Pop` and `Push` messages.

```julia
const forwarder = send
function (sn::StackNode)(msg::Pop)
    isnothing(sn.content) || become(forwarder, sn.link)
    send(msg.customer, sn.content)
end
(sn::StackNode)(msg::Push) = become(StackNode(msg.content, spawn(sn)))
```

Now we can operate the stack:

```julia
julia> mystack = spawn(StackNode(nothing, newLink())) # create the top of the stack
Link{Channel{Any}}(Channel{Any}(sz_max:32,sz_curr:0), 1, :default)

julia> response = newLink()                           # create a response link
Link{Channel{Any}}(Channel{Any}(sz_max:32,sz_curr:0), 1, :local)

julia> for i ∈ 1:5
           send(mystack, Push(i))
       end

julia> for i ∈ 1:5
           send(mystack, Pop(response))
           println(receive(response))
       end
5
4
3
2
1
```

[^1]: Gul Agha 1986. *Actors. a model of concurrent computation in distributed systems*, MIT.- p. 34f
