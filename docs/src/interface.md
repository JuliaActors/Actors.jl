# Interface

```@meta
CurrentModule = Actors
```

Actors provides an interface to other actor libraries working in two directions:

1. Libraries with **different actor primitives** can interface Actors to enable actors of both worlds to communicate with each other and to use the same API.
2. Libraries can **change the actor mode and behavior**.  

## Different actor primitives

On [`JuliaActors`](https://github.com/JuliaActors) there is a companion library [`SlowActors`](https://github.com/JuliaActors/SlowActors.jl) to illustrate the use of the interface. This is a *completely different implementation* of the Actor Model. It doesn't use Julia `Channel`s for message passing and operates without an actor loop. Rather each time a message to a "slow" actor is sent, an actor `Task` is started.

But in using the common [`Link`](@ref) type, actors from both libraries can communicate. With actually few lines of code `SlowActors` plugs in the `Actors` interface and is able to run the identical [examples](https://github.com/JuliaActors/SlowActors.jl/tree/master/examples). It actually only reimplements three primitives: `spawn`, `newLink` and `send!`.

## Different actor mode and behavior

`Actors` provides a mode field in both `Link` and `_ACT`, with `mode=:default` for normal operation.

Other libraries can [`spawn`](@ref) their actors with a different mode, e.g. `mode=:GenServer`. If they then enhance [`onmessage`](@ref) with e.g.

```julia
Actors.onmessage(A::_ACT, ::Val{:GenServer}, msg::Call) = ...
Actors.onmessage(A::_ACT, ::Val{:GenServer}, msg::Cast) = ...
....
```

... they get for those messages a different actor behavior where they can do callbacks or set state or whatever they want to.

Actors spawned with a different mode return a link with the mode field set accordingly.
