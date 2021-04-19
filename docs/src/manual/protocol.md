# Messaging Protocol

```@meta
CurrentModule = Actors
```

`Actors` has predefined [message types](../reference/messages.md) with respective [`onmessage`](@ref) methods. This gives your actors predefined behaviors going beyond the classical [behavior](behaviors.md).

## Messaging Patterns

The actor protocol can be described as a series of messaging patterns. For every predefined message an actor executes a predefined `onmessage` method. Here is an overview:

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

There are messages for bidirectional and unidirectional communication (the latter for actor control without response).

## User API Functions

`Actors`' [user API](../api/user_api.md) functions provide an interface to those message patterns. 

## Enhancing the Protocol

The `Actors` protocol can be enhanced or altered by

- introducing new messages and `onmessage` methods,
- switching the actor mode and writing new `onmessage` methods for existing messages
- or both.

Libraries can do this for specific duties and plugin their protocols into `Actors`. Examples of such libraries are [`GenServers`](https://github.com/JuliaActors/GenServers.jl) and [`Guards`](https://github.com/JuliaActors/Guards.jl).
