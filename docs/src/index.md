# Actors Documentation

`Actors` implements the classical Actor model using Julia's concurrency primitives.

> An actor is a computational entity that, in response to a message it receives, can concurrently:
>
> - *send* a finite number of messages to other actors;
> - *create* a finite number of new actors;
> - designate the *behavior* to be used for the next message it receives. [^1]

Actors enhance Julia's capabilities for concurrent computing. They can be used together with other Julia functionality for multi-threading and distributed computing.

Actors use Julia functions as behaviors and are

- *responsive* – they react to users - and
- *message-driven* - they rely on asynchronous message-passing [^2].

`Actors` has a modern API [^3], can interface with other actor libraries and can be extended by them using actor protocols.

`Actors` is in active development. If you want to contribute, please join [`JuliaActors`](https://github.com/JuliaActors).

[^1]: See the Wikipedia entry on the [Actor Model](https://en.wikipedia.org/wiki/Actor_model).
[^2]: See [The Reactive Manifesto](https://www.reactivemanifesto.org). Its other two tenets *resilient* and *elastic* are prepared for and are likely to come soon.
[^3]: The `Actors` API is inspired by Erlang/OTP, see [OTP Design Principles - User’s Guide](https://erlang.org/doc/design_principles/users_guide.html)