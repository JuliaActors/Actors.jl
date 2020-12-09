# Behaviors

```@meta
CurrentModule = Actors
```

A behavior is a ...

> ... function to express what an actor does when it processes a message. [^1]
>
> The behavior of an actor maps the incoming communication to a three tuple of tasks created, new actors created, and the replacement behavior. [^2]

```math
\begin{array}{lrl}
f_i(a_i, c_i) & \rightarrow &\{f_{i+1}(a_{i+1}),\;\{\tau_u,\tau_v, ...\},\;\{\alpha_x,\alpha_y,...\}\} \quad\\
\textrm{with} & f: & \textrm{behavior function} \\
 & a: & \textrm{acquaintances,} \\
 & c: & \textrm{communication,} \\
 & \tau: & \textrm{tasks created,} \\
 & \alpha: & \textrm{actors created.} \\
\end{array}
```

The behavior thus can be seen as a [partial application](https://en.wikipedia.org/wiki/Partial_application) of a function ``f`` to acquaintances ``a`` (variables or values the actor knows of). If a communication ``c`` arrives, the behavior executes ``f(a,c)``:

```@repl
f(a, c) = a + c         # define a function
g(f, a) = (c)->f(a, c)  # a function to build a behavior
bhv = g(f, 1)           # partially apply f to 1
bhv(2)                  # execute f(1,2)
```

Actor behavior can be represented in a functional or in an object-oriented style. Both are interchangeable.

## Functional Style

We represent a behavior as a function `f` together with acquaintance arguments `a...` and `kw...` (keyword arguments) to it. [`Bhv`](@ref) creates a partial application (a closure) `ϕ(a...; kw...)` which then can be executed with the communication arguments `c...`:

```@repl
using Actors
f(s, t, u, v; w=1, x=1) = s + t + u + v + w + x   # a function
bhv = Bhv(f, 1, 1, w=2, x=2);  # create a Bhv with f and acquaintances
bhv(1, 1)                      # execute it with communication parameters
```

## Object-oriented Style

Alternatively we put the acquaintance parameters in an object which we can make executable (a [functor](https://en.wikipedia.org/wiki/Function_object)) with communication parameters:

```@repl
struct Acqu                    # define an object with acquaintances
    s; t; w; x
end
(a::Acqu)(u, v) = a.s + a.t + u + v + a.w + a.x  # make it executable with communication parameters
bhv = Acqu(1,1,2,2)            # create an instance
bhv(1,1)                       # execute it with communication parameters
```

## Agha's Stack example

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

[^1]: see the [Actor Model](https://en.wikipedia.org/wiki/Actor_model#Behaviors) on Wikipedia.
[^2]: Gul Agha 1986. *Actors. a model of concurrent computation in distributed systems*, MIT.- p. 30
[^3]: ibid. p. 34
