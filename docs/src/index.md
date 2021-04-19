# Welcome to Actors

[`Actors`](https://github.com/JuliaActors/Actors.jl) is a [Julia](https://julialang.org) library for concurrent computing based on the [Actor Model](https://en.wikipedia.org/wiki/Actor_model):

> An actor ... in response to a message it receives, can concurrently:
>
> - *send* a finite number of messages to other actors;
> - *create* a finite number of new actors;
> - designate the *behavior* to be used for the next message it receives. [^1]

Actors make concurrency easy to understand and reason about and integrate well with Julia's multi-threaded and distributed computing. `Actors` provides a modern API [^2] for writing reactive [^3] applications, that are:

- *responsive* : react to inputs and events,
- *resilient* : can cope with failures,
- *elastic* : can distribute load over multiple threads and  workers,
- *message-driven* : rely on asynchronous message-passing.

### Overview

This overview of `Actors`' documentation [^4] will help you know where to look for certain things:

- [*Tutorials*](tutorial/install.md) will help you to learn how to work with actors. Start here if you’re new to `Actors`.
- [*How-to*](howto/spawn.md) guides are recipes. They guide you through the steps involved in addressing key problems and use-cases. They are more advanced than tutorials and assume some knowledge of how actors work.
- [*On Actors*](manual/basics.md) discusses key concepts and provides background information and explanation.
- [*Reference*](api/api.md) contains technical reference for APIs, some examples and internals. It assumes that you have a basic understanding of key concepts.

### Links

- [Actors GitHub repository](https://github.com/JuliaActors/Actors.jl),
- [JuliaActors](https://github.com/JuliaActors/)

[^1]: See the Wikipedia entry on the [Actor Model](https://en.wikipedia.org/wiki/Actor_model)
[^2]: The `Actors` API is inspired by Erlang/OTP, see [OTP Design Principles - User’s Guide](https://erlang.org/doc/design_principles/users_guide.html)
[^3]: See [The Reactive Manifesto](https://www.reactivemanifesto.org)
[^4]: The organization of the docs follows the [Diátaxis Framework](https://diataxis.fr)
