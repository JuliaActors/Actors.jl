# Actors.jl

Concurrent computing in Julia based on the Actor Model

[![stable docs](https://img.shields.io/badge/docs-stable-blue.svg)](https://juliahub.com/docs/Actors)
[![dev docs](https://img.shields.io/badge/docs-dev-blue.svg)](https://JuliaActors.github.io/Actors.jl/dev)
![CI](https://github.com/JuliaActors/Actors.jl/workflows/CI/badge.svg)
[![Coverage](https://codecov.io/gh/JuliaActors/Actors.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaActors/Actors.jl)

The [Actor Model](https://en.wikipedia.org/wiki/Actor_model) of computer science sees an *actor* as the universal primitive of concurrent computation:

> An actor is a computational entity that, in response to a message it receives, can concurrently:
>
> - send a finite number of messages to other actors;
> - create a finite number of new actors;
> - designate the behavior to be used for the next message it receives.

`Actors` implements that with Julia's concurrency primitives and provides a standard and common API for building a modern actor infrastructure. It is part of the Julia GitHub group [`JuliaActors`](https://github.com/JuliaActors).

```julia
julia> using Actors

julia> import Actors: spawn

julia> greet(greeting, msg) = greeting*", "*msg*"!" # a greetings server
greet (generic function with 1 method)

julia> hello(greeter, to) = request(greeter, to)    # a greetings client
hello (generic function with 1 method)

julia> greeter = spawn(Func(greet, "Hello"))  # spawn the server
Link{Channel{Any}}(Channel{Any}(sz_max:32,sz_curr:0), 1, :default)

julia> sayhello = spawn(Func(hello, greeter)) # spawn the client
Link{Channel{Any}}(Channel{Any}(sz_max:32,sz_curr:0), 1, :default)

julia> request(sayhello, "World")
"Hello, World!"

julia> request(sayhello, "Kermit")
"Hello, Kermit!"
```

## Authors

- Oliver Schulz (until v0.1, Oct 2017)
- Paul Bayer (rewrite since v0.1.1, Nov 2020)

## License

MIT
