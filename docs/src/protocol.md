# Message Protocol

```@meta
CurrentModule = Actors
```

Actors can be called, updated, queried … To do it they follow an internal message protocol.

## Internal Messages

The [API](api.md)-functions are mostly using those messages:

```@docs
Become
Call
Cast
Diag
Exit
Exec
Init
Query
Term
Timeout
Update
```

## User extensions

There are three ways to extend the messaging protocol and the functionality of `Actors`:

1. If a user defines its own messages of type [`Msg`](@ref) and sends them to an actor, it passes them on as remaining argument to the behavior function.
2. Alternatively a user can extend [`Actors.onmessage`](@ref onmessage) with his own methods to dispatch on those messages and doing user defined things.
3. Finally a user can implement other message types and messaging protocols and extend `Actors.onmessage` for dispatching on those.
