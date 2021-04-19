# User API

```@meta
CurrentModule = Actors
```

The user API allows you to communicate with actors using the `Actors` [protocol](../manual/protocol.md):

## Bidirectional Communication

The following functions send a message to an actor causing it to respond:

| API function | brief description |
|:-------------|:------------------|
| [`call`](@ref) | tell an actor to execute its behavior function and to send the result |
| [`exec`](@ref) | tell an actor to execute a function and to send the result |
| [`query`](@ref) | tell an actor's to send one of its internal state variables |

Those functions support both asynchronous and synchronous communication.

## Actor Control (Unidirectional)

Actors can be controlled with the following functions:

| API function | brief description |
|:-------------|:------------------|
| [`become!`](@ref) | cause an actor to switch its behavior |
| [`cast`](@ref) | cause an actor to execute its behavior function |
| [`exit!`](@ref) | cause an actor to terminate |
| [`init!`](@ref) | tell an actor to execute a function at startup |
| [`term!`](@ref) | tell an actor to execute a function when it terminates |
| [`update!`](@ref) | update an actor's internal state |

Actors can also operate on themselves, or rather they send themselves messages:

| API function | brief description |
|:-------------|:------------------|
| [`become`](@ref) | an actor switches its own behavior |
| [`stop`](@ref) | an actor stops |

## Functions

```@docs
call
cast
exec
exit!
info
init!
query
term!
update!
```

## Types

The following is needed for updating arguments:

```@docs
Args
```
