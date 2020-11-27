# Introduction

```@meta
CurrentModule = Actors
```

This example shows the basic primitives of `Actors`:

- [`spawn`](@ref): create an actor and get a [`Link`](@ref) to it,
- [`send`](@ref): send it a message,
- [`become!`](@ref): cause it to change its behavior.

```julia
julia> using Actors, Printf

julia> import Actors: spawn                 # this has to be imported

julia> function pr(msg)                     # define two functions for printing a message
           print(@sprintf("%s\n", msg))
           become(pr, "Next") # change behavior
       end
pr (generic function with 1 method)

julia> pr(info, msg) = print(@sprintf("%s: %s\n", info, msg))
pr (generic function with 2 methods)

julia> calc(op, x, y) = op(x, y)            # a function for doing arithmetic
calc (generic function with 1 method)

julia> myactor = spawn(Func(pr))            # start an actor with the first behavior
Link{Channel{Any}}(Channel{Any}(sz_max:32,sz_curr:0), 1, :local)

julia> send(myactor, "My first actor");    # send a message to it
My first actor

julia> send(myactor, "Something else")     # send again a message
Next: Something else

julia> become!(myactor, pr, "New behavior");# change the behavior to another one

julia> send(myactor, "bla bla bla")        # and send again a message
New behavior: bla bla bla

julia> become!(myactor, calc, +, 10);       # become a machine for adding to 10

julia> request(myactor, 5)                 # send a request to add 5
15

julia> become!(myactor, ^);                 # become a exponentiation machine

julia> request(myactor, 123, 456)          # try it
2409344748064316129
```
