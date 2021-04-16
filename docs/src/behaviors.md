# Actor Behavior

```@meta
CurrentModule = Actors
```

An actor embodies the essential elements of  computation: 1) processing, 2) storage and 3) communication.[^1] Its behavior therefore can be described as ``f(a)[c]``,  representing

1. ``f``: a function, *processing*,
2. ``a``: acquaintances, *storage*, data that it has,
3. ``c``: *communication*, a message.

It processes an incoming message ``c`` with its behavior function ``f`` based on its acquaintances ``a``.

> When an Actor receives a message, it can concurrently:
>
> - send messages to ... addresses of Actors that it has;
> - create new Actors;
> - designate how to handle the next message it receives. [^2]

Gul Agha described the *behavior* as a ...

> ... function of the incoming communication.
>
> Two lists of identifiers are used in a behavior definition. Values for the first list of parameters must be specified when the actor is created. This list is called the *acquaintance list*. The second list of parameters, called the *communication list*, gets its bindings from an incoming communication. [^3]

A behavior then maps the incoming communication to a three tuple of messages sent, new actors created and the replacement behavior:

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

## Behavior Representation in Julia

`Actors` expresses actor behavior in a functional style. Actors are basically *function servers*. Their behavior is a [partial application](https://en.wikipedia.org/wiki/Partial_application) of a callable object ``f(a...,c...)`` to acquaintances ``a...``, that is, a closure over ``f(a...)``. If the actor receives a communication ``c...``, the closure invokes ``f(a...,c...)``. The [`...`-operator](https://docs.julialang.org/en/v1.6/manual/faq/#What-does-the-...-operator-do?) allows us to use multiple acquaintance and communication arguments (i.e. lists).

```@repl
f(a, c) = a + c         # define a function
partial(f, a...; kw...) = (c...) -> f(a..., c...; kw...)
bhv = partial(f, 1)     # partially apply f to 1, return a closure
bhv(2)                  # execute f(1,2)
```

Similar to the `partial` above, [`Bhv`](@ref) is a convenience function to create a partial application `ϕ(a...; kw...)` with optional keyword arguments, which can be executed with communication arguments `c...`:

```@repl bhv
using Actors, .Threads
import Actors: spawn, newLink
f(s, t; w=1, x=1) = s + t + w + x   # a function
bhv = Bhv(f, 2, w=2, x=2);          # create a behavior of f and acquaintances
bhv(2)                              # execute it with a communication parameter
```

### Object-oriented Style

Alternatively we define an object with some data (acquaintances) and make it [callable (as a functor)](https://en.wikipedia.org/wiki/Function_object) with communication parameters:

```@repl bhv
struct A                            # define an object 
    s; w; x                         # with acquaintances
end
(a::A)(t) = a.s + a.w + a.x + t     # make it a functor, executable with a communication parameter t
bhv = A(2, 2, 2)                    # create an instance
bhv(2)                              # execute it with a parameter
```

## Actor Operation

When we create an actor with a behavior by using [`spawn`](@ref), it is ready to receive communication arguments and to process them:

1. You can create an actor with anything callable as behavior regardless whether it contains acquaintances or not.
2. Over its [`Link`](@ref) you can [`send`](@ref) it communication arguments and cause the actor to execute its behavior with them. `Actors`' [API](api.md) functions like [`call`](@ref), [`exec`](@ref) are just wrappers around `send` and [`receive`](@ref) using a communication [protocol](protocol.md).
3. If an actor receives wrong/unspecified communication arguments, it will fail with a `MethodError`.
4. With [`become!`](@ref) and [`become`](@ref) we can change an actor's behavior.

```@repl bhv
me = newLink()
myactor = spawn(()->send(me, threadid()),thrd=2) # create an actor with a parameterless anonymous behavior function
send(myactor)                                    # send it an empty tuple
receive(me)                                      # receive the result
become!(myactor, threadid)
call(myactor)                                    # call it without arguments
become!(myactor, (lk, x, y) -> send(lk, x^y))    # an anonymous function with communication arguments
send(myactor, me, 123, 456)                      # send it arguments
receive(me)                                      # receive the result
```

In setting actor behavior you are free to mix the functional and object oriented approaches. For example you can give functors further acquaintance parameters (as for the players in the [table-tennis example](@ref table-tennis)). Of course you can give objects containing acquaintances as parameters to a function and create a partial application with `Bhv` on them and much more.

## Actors Don't Share State

Actors must not share state in order to avoid race conditions. Acquaintance and communication parameters are actor state. `Actors` does not disallow for an actor to access and to modify mutable variables. It is therefore left to the programmer to exclude race conditions by not sharing them with other actors or tasks and accessing them concurrently. In most cases you can control which variables get passed to an actor and avoid to share them.

Note that when working with distributed actors, variables get copied automatically when sent over a `Link` (a `RemoteChannel`).

### Share Actors Instead Of Memory

But in many cases you want actors or tasks to concurrently use the same variables. You can then thread-safely model those as actors and share their links between actors and tasks alike. Each call to a link is a communication to an actor (instead of a concurrent access to a variable):

- In the [table-tennis](@ref table-tennis) example player actors working on different threads share a print server actor controlling access to the `stdio` variable.
- In the [Dict-server](@ref dict-server) example a `Dict` variable gets served by an actor to tasks on parallel threads or workers.
- In the [Dining Philosophers](examples/dining_phil.md) problem the shared chopsticks are expressed as actors. This avoids races and starvation between the philosopher actors.
- In the [Producer-Consumer](examples/prod_cons.md) problem producers and consumers share a buffer modeled as an actor.
- You can wrap mutable variables into a [`:guard`](https://github.com/JuliaActors/Guards.jl) actor, which will manage access to them.
- In more complicated cases of resource sharing you can use a [`:genserver`](https://github.com/JuliaActors/GenServers.jl) actor.

To model concurrently shared objects or data as actors is a common and successful pattern in actor programming. It makes it easier to write clear, correct concurrent programs. Unlike common tasks or also shared variables, actors are particularly suitable for this modeling because

1. they are persistent objects like the variables or objects they represent and
2. they can express a behavior of those objects.

[^1]: [Hewitt, Meijer and Szyperski: The Actor Model (everything you wanted to know, but were afraid to ask)](http://channel9.msdn.com/Shows/Going+Deep/Hewitt-Meijer-and-Szyperski-The-Actor-Model-everything-you-wanted-to-know-but-were-afraid-to-ask), Microsoft Channel 9. April 9, 2012.
[^2]: Carl Hewitt. Actor Model of Computation: Scalable Robust Information Systems.- [arXiv:1008.1459](https://arxiv.org/abs/1008.1459).
[^3]: Gul Agha 1986. *Actors. a model of concurrent computation in distributed systems*, MIT.- p. 30
