# Actor API

```@meta
CurrentModule = Actors
```

## Installation

```@docs
Actors
Actors.version
```

```@repl
using Actors
Actors.version
```

## Types

The following types are needed for using and extending `Actors`:

```@docs
Msg
Request
Response
Link
Func
_ACT
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
send!
become!
become
self
stop
onmessage
```

## API Primitives

To receive messages from actors the following two functions for synchronous and asynchronous communication are useful:

```@docs
receive!
request!
```

## User API

Actors has a user interface allowing you to control actors:

```@docs
call!
cast!
exec!
exit!
query!
update!
```

The following is needed for updating arguments:

```@docs
Args
```

## Actor Registry

## Actor Supervision

This is not yet implemented.

```@docs
init!
term!
```

## Diagnosis
