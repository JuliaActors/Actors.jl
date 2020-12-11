# Actors Documentation

`Actors` implements the Actor model using Julia's concurrency primitives.

> An actor is a computational entity that, in response to a message it receives, can concurrently:
>
> - *send* a finite number of messages to other actors;
> - *create* a finite number of new actors;
> - designate the *behavior* to be used for the next message it receives. [^1]

`Actors` enhances Julia's capabilities for concurrent computing. It can be used together with other Julia functionality for multi-threading and distributed computing.

`Actors` builds on the classical Actor model. Its actors have Julia functions as behaviors and can be controlled and interact with a modern API (inspired by Erlang/Elixir/OTP).

`Actors` can interface with other actor libraries and can be extended by them using actor protocols.

`Actors` is in active development. If you want to contribute, please join [`JuliaActors`](https://github.com/JuliaActors).

[^1]: See the Wikipedia entry on the [Actor Model](https://en.wikipedia.org/wiki/Actor_model).