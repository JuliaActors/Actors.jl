# Actors.jl

Concurrent computing in Julia with actors.

[![stable docs](https://img.shields.io/badge/docs-stable-blue.svg)](https://juliaactors.github.io/Actors.jl/stable/)
[![dev docs](https://img.shields.io/badge/docs-dev-blue.svg)](https://JuliaActors.github.io/Actors.jl/dev)
![CI](https://github.com/JuliaActors/Actors.jl/workflows/CI/badge.svg)
[![Coverage](https://codecov.io/gh/JuliaActors/Actors.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaActors/Actors.jl)

`Actors` implements the [Actor Model](https://en.wikipedia.org/wiki/Actor_model) of computation:

> An actor ... in response to a message it receives, can concurrently:
>
> - send a finite number of messages to other actors;
> - create a finite number of new actors;
> - designate the behavior to be used for the next message it receives.

`Actors` make(s) concurrency easy to understand and reason about and integrate(s) well with Julia's multi-threading and distributed computing. It provides an API for writing [reactive](https://www.reactivemanifesto.org) applications, that are:

- *responsive*: react to inputs and events,
- *message-driven*: rely on asynchronous message-passing,
- *resilient*: can cope with failures,
- *elastic*: can distribute load over multiple threads and  workers.

## Greeting Actors

The following example defines two behavior functions: `greet` and `hello` and spawns two actors with them. `sayhello` will forward a message to `greeter`, get a greeting string back and deliver it as a result:

```julia
julia> using Actors

julia> import Actors: spawn

julia> greet(greeting, msg) = greeting*", "*msg*"!" # a greetings server
greet (generic function with 1 method)

julia> hello(greeter, to) = request(greeter, to)    # a greetings client
hello (generic function with 1 method)

julia> greeter = spawn(greet, "Hello")              # start the server with a greet string
Link{Channel{Any}}(Channel{Any}(sz_max:32,sz_curr:0), 1, :default)

julia> sayhello = spawn(hello, greeter)             # start the client with a link to the server
Link{Channel{Any}}(Channel{Any}(sz_max:32,sz_curr:0), 1, :default)

julia> request(sayhello, "World")                   # request the client
"Hello, World!"

julia> request(sayhello, "Kermit")
"Hello, Kermit!"
```

Please look into [the manual](https://JuliaActors.github.io/Actors.jl/dev) for more information and more serious examples.

## Development

`Actors` is part of the Julia GitHub group [JuliaActors](https://github.com/JuliaActors). Please join!

## Authors

- Oliver Schulz (until v0.1, Oct 2017)
- Paul Bayer (rewrite since v0.1.1, Nov 2020)

## License

MIT
