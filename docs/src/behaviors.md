# Actor Behavior

```@meta
CurrentModule = Actors
```

An actor embodies the essential elements of  computation: 1) processing, 2) storage and 3) communication.
> When an Actor receives a message, it can concurrently:
>
> - send messages to ... addresses of Actors that it has;
> - create new Actors;
> - designate how to handle the next message it receives. [^1]

For that Gul Agha introduced the *behavior* as a ...

> ... function of the incoming communication. 
> 
> Two lists of identifiers are used in a behavior definition. Values for the first list of parameters must be specified when the actor is created. This list is called the *acquaintance list*. The second list of parameters, called the *communication list*, gets its bindings from an incoming communication. [^2]

Thus a behavior maps the incoming communication to a three tuple of messages sent, new actors created and the replacement behavior:

```math
\begin{array}{lrl}
f_i(a_i)[c_i] & \rightarrow &\{\{\mu_u,\mu_v, ...\},\;\{\alpha_x,\alpha_y,...\},\;f_{i+1}(a_{i+1})\} \quad\\
\textrm{with} & f: & \textrm{behavior function} \\
 & a: & \textrm{acquaintances,} \\
 & c: & \textrm{communication,} \\
 & \mu: & \textrm{messages sent,} \\
 & \alpha: & \textrm{actors created.} \\
\end{array}
```

`Actors` represents a behavior as [partial application](https://en.wikipedia.org/wiki/Partial_application) of a function ``f`` to acquaintances ``a`` (variables, values or actors the actor knows of). If a communication ``c`` arrives, the behavior executes ``f(a,c)``:

```@repl
f(a, c) = a + c         # define a function
partial(f, a...; kw...) = (c...) -> f(a..., c...; kw...)
bhv = partial(f, 1)     # partially apply f to 1
bhv(2)                  # execute f(1,2)
```

Actor behavior can be represented in a functional or in an object-oriented style. Both are interchangeable.

## Functional Style

The behavior is a function `f` together with acquaintance arguments `a...` and `kw...` (keyword arguments) to it. [`Bhv`](@ref) creates a partial application (a closure) `ϕ(a...; kw...)` which  can be executed with communication arguments `c...`:

```@repl
using Actors
f(s, t, u, v; w=1, x=1) = s + t + u + v + w + x   # a function
bhv = Bhv(f, 1, 1, w=2, x=2);  # create a Bhv with f and acquaintances
bhv(1, 1)                      # execute it with communication parameters
```

## Object-oriented Style

Alternatively we put the acquaintance parameters in an object which we make executable (see: [function object](https://en.wikipedia.org/wiki/Function_object)) with communication parameters:

```@repl
struct Acqu                    # define an object with acquaintances
    s; t; w; x
end
(a::Acqu)(u, v) = a.s + a.t + u + v + a.w + a.x  # make it executable with communication parameters
bhv = Acqu(1,1,2,2)            # create an instance
bhv(1,1)                       # execute it with communication parameters
```

## Freestyle

With being callable the only hard requirement for a behavior, you can pass anything callable as behavior to an actor regardless whether it contains acquaintances or not:

```@repl
using Actors, .Threads
import Actors: spawn, newLink
myactor = spawn(threadid)                     # a parameterless function
call(myactor)
become!(myactor, (lk, x, y) -> send(lk, x^y)) # an anonymous function with communication arguments
me = newLink()
send(myactor, me, 123, 456)
receive(me)
```

You can give functors further acquaintance parameters (as for the players in the [table-tennis example](@ref table-tennis)). Of course you can give objects containing acquaintances as parameters to a function and create a partial application with `Bhv` on them and much more. Be my guest!

## [Agha's Stack example](@id stack)

Now more realistically for actor behavior we reproduce Agha's example 3.2.1 [^3]:

```julia
using Actors
import Actors: spawn, newLink

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

# now three behavior methods
forwarder = send
function (sn::StackNode)(msg::Pop)
    isnothing(sn.content) || become(forwarder, sn.link)
    send(msg.customer, Response(sn.content))
end
(sn::StackNode)(msg::Push) = become(StackNode(msg.content, spawn(sn)))
```

Here we use both the functional and the object oriented approach:

- `forwarder` is a function which we put together with `sn.link` into a `Bhv`,
- `StackNode` is an object, which gets two methods.

Now we can operate the stack:

```julia
julia> mystack = spawn(StackNode(nothing, newLink()))
Link{Channel{Any}}(Channel{Any}(sz_max:32,sz_curr:0), 1, :default)

julia> response = newLink()
Link{Channel{Any}}(Channel{Any}(sz_max:32,sz_curr:0), 1, :local)

julia> for i ∈ 1:5
           send(mystack, Push(i))
       end

julia> for i ∈ 1:5
           send(mystack, Pop(response))
           println(receive(response).y)
       end
5
4
3
2
1
```

## Setting and Changing Behavior

An actor's behavior is set with [`spawn`](@ref) and gets changed with [`become!`](@ref). Inside a behavior function an actor can change its own behavior with [`become`](@ref). In both cases a callable object together with acquaintance arguments can be specified as new behavior. This is effective when the next message gets processed.

## Don't Share Mutable Variables

As you have seen, you are very free in how you define behaviors, but you must be very careful in passing mutable variables as acquaintances to actors as they could be accessed by other actors on other threads concurrently causing race conditions. 

## Instead Share Actors

It is thread-safe to share actors between threads or other actors. Each call to the shared actor is a communication.

- In the [table-tennis](@ref table-tennis) example we shared a print server actor between player actors working on different threads.
- In the [Dict-server](@ref dict-server) example a dictionary gets served by an actor to parallel threads.
- You can wrap mutable variables into a [`:guard`](https://github.com/JuliaActors/Guards.jl) actor, which will manage access to them.
- In more complicated cases of resource sharing you can use a [`:genserver`](https://github.com/JuliaActors/GenServers.jl) actor.

As those examples show, it is surprisingly easy to avoid race conditions by using actors.

[^1]: Carl Hewitt. Actor Model of Computation: Scalable Robust Information Systems.- [arXiv:1008.1459](https://arxiv.org/abs/1008.1459).
[^2]: Gul Agha 1986. *Actors. a model of concurrent computation in distributed systems*, MIT.- p. 30
[^3]: ibid. p. 34
