# Messaging Protocol

```@meta
CurrentModule = Actors
```

`Actors` has predefined [message types](messages.md) with respective [`onmessage`](@ref) methods. This gives your actors predefined behaviors going beyond the classical [behavior](behaviors.md). API functions provide an interface to that messaging protocol and facilitate actor control and message exchange.

## Messaging Patterns

The actor protocol can be described as a series of messaging patterns. For every predefined message the actor executes a predefined behavior. Here is an overview:

| Message pattern | brief description |
|:----------------|:------------------|
| [`Become`](@ref) | Tell an actor to change its behavior. |
| [`Call`](@ref) - [`Response`](@ref) | Call an actor to execute its behavior and to respond with the result. | [`Cast`](@ref) | Cast an actor a message to execute its behavior. |
| [`Diag`](@ref) - [`Response`](@ref) | Call an actor to respond with diagnostic information. |
| [`Down`](@ref) | A message to a monitor actor signaling an exit or a failure. |
| [`Exit`](@ref) | A message causing an actor to exit. |
| [`Exec`](@ref) - [`Response`](@ref) | Call an actor to execute a function and to respond with the result. |
| [`Init`](@ref) | Tell an actor to execute an initialization function and to store it in its internal state. |
| [`Query`](@ref) - [`Response`](@ref) | Call an actor to send a status variable/value. |
| [`Request`](@ref) | This triggers the actor's default response to execute its behavior. |
| [`Term`](@ref) | Tell an actor to execute a given behavior upon termination. |

`Actors` API functions are wrappers to those message patterns. As you have seen there are unidirectional messages (without response) for actor control and bidirectional messages.

## Actor Control

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
| [`self`](@ref) | an actor gets a link to itself |
| [`stop`](@ref) | an actor stops |

## Bidirectional Messages

To receive a reply from an actor there are two possibilities:

| API function | brief description |
|:-------------|:------------------|
| [`receive`](@ref) | after a [`send`](@ref) receive the [`Response`](@ref) asynchronously |
| [`request`](@ref) | `send` (implicitly) a message to an actor, **block** and `receive` the result synchronously |

The following functions do that for specific duties:

| API function | brief description |
|:-------------|:------------------|
| [`call`](@ref) | tell an actor to execute its behavior function and to send the result |
| [`exec`](@ref) | tell an actor to execute a function and to send the result |
| [`query`](@ref) | tell an actor's to send one of its internal state variables |

Those functions support both asynchronous and synchronous communication.

## Enhancing the Protocol

The `Actors` protocol can be enhanced or altered by

- introducing new messages and `onmessage` methods,
- switching the actor mode and writing new `onmessage` methods for existing messages
- or both.

Libraries can do this for specific duties and plugin their protocols into `Actors`. Examples of such libraries are [`GenServers`](https://github.com/JuliaActors/GenServers.jl) and [`Guards`](https://github.com/JuliaActors/Guards.jl).
