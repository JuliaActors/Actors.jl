# Connections

```@meta
CurrentModule = Actors
```

Connected actors send each other [`Exit`](@ref) signals and terminate together unless they are made `:sticky` with `trapExit`:

```@docs
connect
disconnect
trapExit
```
