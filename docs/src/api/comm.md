# Communication

## Receiving a message

To receive a reply from an actor there are two possibilities:

1. *asynchronous* bidirectional communication and
2. *synchronous* bidirectional communication.

| API function | brief description |
|:-------------|:------------------|
| [`receive`](@ref) | after a [`send`](@ref) receive the response asynchronously |
| [`request`](@ref) | `send` (implicitly) a message to an actor, **block** and `receive` the response synchronously |

Both calls block until a message is received or until it times out.

```@docs
receive
request
```

## Delays

An actor should be responsive. Therefore you should avoid to `sleep` within behavior functions. For delayed actions an actor can send instead a delayed message with `send_after` to other actors or to [`self()`](@ref self).

```@docs
send_after
```
