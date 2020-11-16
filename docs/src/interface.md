# Interface

On [`JuliaActors`](https://github.com/JuliaActors) there is a companion library [`SlowActors`](https://github.com/JuliaActors/SlowActors.jl) to illustrate the use of the interface. This is a *completely different implementation* of the Actor Model. It doesn't use Julia `Channel`s for message passing and operates without an actor loop. Rather each time a message to a "slow" actor is sent, an actor `Task` is started.

But in using the common [`Link`](@ref) type, actors from both libraries can communicate. With actually few lines of code `SlowActors` plugs in the `Actors` interface and is able to run the identical [examples](https://github.com/JuliaActors/SlowActors.jl/tree/master/examples). It actually only reimplements three primitives: `spawn`, `newLink` and `send!`.
