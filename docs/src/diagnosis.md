# Diagnosis

```@meta
CurrentModule = Actors
```

In order to develop actor programs, it is useful to have access to the actor tasks and eventually to their stack traces. 

```@docs
istaskfailed(::Link)
info
```

For diagnostic purposes it is possible to get access to the actor's [`ACT`](@ref _ACT) variable:

```@docs
diag
```
