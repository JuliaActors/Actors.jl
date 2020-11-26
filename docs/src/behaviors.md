# Behaviors

```@meta
CurrentModule = Actors
```

A behavior is a ...

> ... function to express what an actor does when it processes a message. [^1]
>
> Two lists of identifiers are used in a behavior definition. Values for the first list of parameters must be specified when the actor is created. This list is called the *acquaintance list*. The second list of parameters, called the *communication list*, gets its bindings from an incoming communication. An actor executes commands in its script in the *environment* defined by the bindings of the identifiers in the acquaintance and communication lists. [^2]

From this we get for a behavior function ``f`` at instance ``i``:

```math
\begin{array}{lrl}
f_i(a_i, c_i) & \rightarrow &\{a_{i+1},\{\tau_u,\tau_v, ...\},\{\alpha_x,\alpha_y,...\},\phi_{i+1}\} \quad\\
\textrm{with} & a: & \textrm{acquaintance list,} \\
 & c: & \textrm{communication list,} \\
 & \tau: & \textrm{tasks created,} \\
 & \alpha: & \textrm{actors created.} \\
\end{array}
```

The behavior function may change its acquaintances or make new ones and thus change its acquaintance list from ``a_i`` to ``a_{i+1}`` and may also specify a replacement behavior ``\phi_{i+1}`` for the subsequent communication.

## Behavior representation

`Actors` represents a behavior as a [`Func`](@ref) containing

- a callable object `f` together with 
- acquaintance arguments `a...` and `kw...` (keyword arguments) to it. 

From those a `Func` creates a partial function (a closure) `ϕ(a...; kw...)` which can be executed with the communication arguments `c...`:

```@repl
using Actors
f(s, t, u, v; w=1, x=1) = s + t + u + v + w + x   # a function
a = (1, 1)                    # define acquaintance arguments
kw = (w=2, x=2)               # define acquaintance keyword arguments
func = Func(f, a...; kw...);  # create a Func with them
c = (1, 1)                    # define communication arguments
func(c...)                    # execute func with them
f(a..., c...; kw...)          # this is how f gets dispatched
```

The acquaintance (or partial) arguments can constrain the behavior function `f` to work with e.g. given values, a certain database, a state variable, a user request ... 

## [Behavior Dispatch](@id dispatch)

On a message, an actor composes its partial arguments with the newly received ones and dispatches the behavior function. The arguments are composed from left to right, first the partial arguments, then the received ones.

## Setting and changing behavior

An actor's behavior is set with [`spawn`](@ref) and gets changed with [`become!`](@ref). Inside a behavior function an actor can change its own behavior with [`become`](@ref). In both cases a callable object together with acquaintance arguments can be specified as new behavior. This is  effective when the next message gets processed.

[^1]: see the [Actor Model](https://en.wikipedia.org/wiki/Actor_model#Behaviors) on Wikipedia.
[^2]: Gul Agha 1986. *Actors. a model of concurrent computation in distributed systems*, MIT.- p. 30
