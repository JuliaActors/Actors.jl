# Actor Registry

```@meta
CurrentModule = Actors
```

Actors can be registered with `Symbol`s to a registry. API functions on actors can then be called with their registered names.

```@docs
register
unregister
whereis
registered
```

The registry works transparently over distributed worker processes such that local links are transformed to remote links when shared between workers.
