# Actors.jl

Concurrent computing in Julia based on the Actor Model

[![stable docs](https://img.shields.io/badge/docs-stable-blue.svg)](https://juliahub.com/docs/Actors)
[![dev docs](https://img.shields.io/badge/docs-dev-blue.svg)](https://JuliaActors.github.io/Actors.jl/dev)
![CI](https://github.com/JuliaActors/Actors.jl/workflows/CI/badge.svg)
[![Coverage](https://codecov.io/gh/JuliaActors/Actors.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaActors/Actors.jl)

The classical [Actor Model](https://en.wikipedia.org/wiki/Actor_model) can be described as follows:

> An actor is a computational entity that, in response to a message it receives, can concurrently:
>
> - send a finite number of messages to other actors;
> - create a finite number of new actors;
> - designate the behavior to be used for the next message it receives.

`Actors` implements this based on Julia's concurrency primitives, and provides  a standard and common API for building a modern actor infrastructure. It is part of the Julia GitHub group [`JuliaActors`](https://github.com/JuliaActors).

## Authors

- Oliver Schulz (until v0.1, Oct 2017)
- Paul Bayer (rewrite since v0.1.1, Nov 2020)

## License

MIT
