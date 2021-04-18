# Install and Use `Actors`

`Actors` requires at least Julia 1.6.

You enter `pkg>`-mode by typing `]` in the Julia REPL. Then you can install the current stable, registered version with

```julia
pkg> add Actors
```

The development version is installed with:

```julia
pkg> add "https://github.com/JuliaActors/Actors.jl"
```

You can then use it for your work:

```@repl
using Actors
Actors.version
```
