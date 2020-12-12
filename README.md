# Actors.jl

Concurrent computing in Julia based on the Actor Model

[![stable docs](https://img.shields.io/badge/docs-stable-blue.svg)](https://juliaactors.github.io/Actors.jl/stable/)
[![dev docs](https://img.shields.io/badge/docs-dev-blue.svg)](https://JuliaActors.github.io/Actors.jl/dev)
![CI](https://github.com/JuliaActors/Actors.jl/workflows/CI/badge.svg)
[![Coverage](https://codecov.io/gh/JuliaActors/Actors.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaActors/Actors.jl)

The [Actor Model](https://en.wikipedia.org/wiki/Actor_model) of computer science sees an *actor* as the universal primitive of concurrent computation:

> An actor is a computational entity that, in response to a message it receives, can concurrently:
>
> - send a finite number of messages to other actors;
> - create a finite number of new actors;
> - designate the behavior to be used for the next message it receives.

`Actors` implements the classical Actor model based on Julia's concurrency primitives.

It integrates well with other Julia functionality for multi-threading and distributed computing.

Beyond that it provides a standard and common API for working with actors and for building a modern actor infrastructure. It is part of the Julia GitHub group [`JuliaActors`](https://github.com/JuliaActors).

As of now `Actors` meets two of the four tenets of the [Reactive Manifesto](https://www.reactivemanifesto.org). Actors are:

- *Responsive*: they react to users.
- *Message-Driven*: they rely on asynchronous message-passing.

The other two tenets are prepared for and likely to come soon:

- *Resilience*: error handling and supervisors,
- *Elasticity*: actor infrastructure libraries.

## Greeting Actors

The following example defines two behaviors: `greet` and `hello` and spawns two actors with them. If it receives a message `sayhello` will forward it to `greeter` and get a greeting string back:

```julia
julia> using Actors

julia> import Actors: spawn

julia> greet(greeting, msg) = greeting*", "*msg*"!" # a greetings server
greet (generic function with 1 method)

julia> hello(greeter, to) = request(greeter, to)    # a greetings client
hello (generic function with 1 method)

julia> greeter = spawn(greet, "Hello")  # spawn the server
Link{Channel{Any}}(Channel{Any}(sz_max:32,sz_curr:0), 1, :default)

julia> sayhello = spawn(hello, greeter) # spawn the client
Link{Channel{Any}}(Channel{Any}(sz_max:32,sz_curr:0), 1, :default)

julia> request(sayhello, "World")
"Hello, World!"

julia> request(sayhello, "Kermit")
"Hello, Kermit!"
```

## Development

`Actors` is in active development. Please join!

## Authors

- Oliver Schulz (until v0.1, Oct 2017)
- Paul Bayer (rewrite since v0.1.1, Nov 2020)

## License

MIT
