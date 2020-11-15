# Actor API

```@meta
CurrentModule = Actors
```

## Installation

```@docs
Actors
Actors.version
```

## Types

```@docs
Msg
Request
Response
Link
Func
_ACT
```

## Starting Actors, creating links

`Actors.jl` doesn't export its functions to start actors and to create links. Thereby other libraries building on it can implement their own actors and links.

If you want to use standard actors and links, you can import them explicitly:

```julia
using Actors
import Actors: spawn, newLink
```

Then you can create them as follows:

```@docs
spawn
newLink
```

## Primitives

```@docs
send!
become!
become
self
stop
onmessage
```

## User API

```@docs
receive!
request!
```

## Internal Messages

```@docs
Become
Call
Diag
Exit
Update
Timeout
```

## Diagnosis
