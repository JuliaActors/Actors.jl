# Actor Primitives

```@meta
CurrentModule = Actors
```

The following primitives characterize actors in the classical Actor Model:

| Primitive             | Brief description            |
|:----------------------|:-----------------------------|
| [`self`](@ref) | get the address of the current actor, |
| [`spawn`](@ref) | create an actor from a behavior and return an address, |
| [`send`](@ref) | send a message to an actor, |
| [`become`](@ref) | an actor designates a new behavior, |

## Functions

```@docs
send
become!
become
self
stop
```
