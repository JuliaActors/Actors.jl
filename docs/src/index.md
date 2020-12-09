# Actors Documentation

`Actors` is a Julia library implementing the Actor model.

> An actor is a computational entity that, in response to a message it receives, can concurrently:
>
> - *send* a finite number of messages to other actors;
> - *create* a finite number of new actors;
> - designate the *behavior* to be used for the next message it receives. [^1]

`Actors` uses Julia's concurrency primitives and enhances its capabilities for concurrent computing.

It can interface with other actor libraries and can be extended by other libraries by actor protocols.

Actors is in active development. If you want to contribute, please join  [`JuliaActors`](https://github.com/JuliaActors).

[^1]: See the Wikipedia entry on the [Actor Model](https://en.wikipedia.org/wiki/Actor_model).