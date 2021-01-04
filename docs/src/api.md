# Actor API

```@meta
CurrentModule = Actors
```

```@docs
Actors
Actors.version
```

```@repl
using Actors
Actors.version
```

## Basic Types

The following types are needed for using and extending `Actors`:

```@docs
Msg
Request
Response
Link
Bhv
_ACT
```

You can create your own message types with

```@docs
@msg
```

## Starting Actors, creating links

`Actors.jl` doesn't export its functions to start actors and to create links. Thus other libraries building on it can implement their own actors and links.

To use `Actors`'s actors and links you import them explicitly:

```julia
using Actors
import Actors: spawn, newLink
```

Then you can create them with the following functions:

```@docs
spawn
newLink
```

## Actor Primitives

The following primitives characterize actors in the classical Actor Model:

```@docs
send
become!
become
self
stop
onmessage
```

## API Primitives

To receive messages from actors the following two functions for synchronous and asynchronous communication can be used:

```@docs
receive
request
```

## User API

The user API allows you to communicate with actors using the `Actors` [protocol](protocol.md):

```@docs
call
cast
exec
exit!
query
update!
```

The following is needed for updating arguments:

```@docs
Args
```

## Actor Tasks

```@docs
ATask
async
await
```

## Actor Registry

Actors can be registered with `Symbol`s to a registry. API functions on actors can then be called with their registered names.

```@docs
register
unregister
whereis
registered
```

The registry works transparently over distributed worker processes such that local links are transformed to remote links when shared between workers.

## Actor Supervision

```@docs
ActorExit
Connection
init!
term!
connect
disconnect
monitor
demonitor
trapExit
```

## Utilities

```@docs
tid
```

## Diagnosis

In order to develop actor programs, it is useful to have access to the actor tasks and eventually to their stack traces. 

```@docs
istaskfailed(::Link)
info
```

For diagnostic purposes it is possible to get access to the actor's [`ACT`](@ref _ACT) variable:

```@docs
diag
```
