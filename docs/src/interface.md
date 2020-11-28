# Interface

```@meta
CurrentModule = Actors
```

!!! warning "The interface is yet experimental!"

    Most of the following needs yet work and will be demonstrable with the upcoming v0.2 release.

`Actors` provides a versatile interface to work with other actor libraries in the [`JuliaActors`](https://github.com/JuliaActors) ecosystem or to allow programmers and users alike to extend its functionality:

1. It is written against `ActorInterfaces.Classic`. Thus it can execute programs written with the primitives in that interface.
2. Actors from other libraries written with that interface have actor level compatibility. Thus they can exchange messages, use the Actors registry (and upcoming supervision).
3. Other libraries written against that interface can plugin the `Actors`' `onmessage` protocol and thus inherit the user API functions: [`call`](@ref), [`cast`](@ref) ...
4. Other party libraries can start actors in another mode and implement a different `onmessage` protocol to make their actors do different things.
5. Users can enhance the [`Msg`] types implemented and extend the `onmessage` methods for working with those messages.

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
