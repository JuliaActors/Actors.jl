# Starting Actors, creating links

```@meta
CurrentModule = Actors
```

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
