# Actors Documentation

`Actors` implements the Actor model of computation:

> An actor ... in response to a message it receives, can concurrently:
>
> - *send* a finite number of messages to other actors;
> - *create* a finite number of new actors;
> - designate the *behavior* to be used for the next message it receives. [^1]

Actors enhance Julia's capabilities for concurrent computing. They can be used together with other Julia functionality for multi-threading and distributed computing.

`Actors` make(s) concurrency easy to understand and reason about and integrate(s) well with Julia's multi-threading and distributed computing. It provides a modern API [^2] for writing reactive [^3] applications, that are:

- *responsive*: react to inputs and events,
- *resilient*: can cope with failures,
- *elastic*: can distribute load over multiple threads and  workers,
- *message-driven*: rely on asynchronous message-passing.

[^1]: See the Wikipedia entry on the [Actor Model](https://en.wikipedia.org/wiki/Actor_model).
[^2]: The `Actors` API is inspired by Erlang/OTP, see [OTP Design Principles - User’s Guide](https://erlang.org/doc/design_principles/users_guide.html)
[^3]: See [The Reactive Manifesto](https://www.reactivemanifesto.org).
