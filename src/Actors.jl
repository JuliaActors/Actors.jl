#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#
"""
    Actors

A Julia library implementing the classical Actor Model.

The current stable, registered version is installed with
```julia
pkg> add Actors
```

The development version is installed with:
```julia
pkg> add "https://github.com/JuliaActors/Actors.jl"
```
"""
module Actors

"Gives the package version."
const version = v"0.1.3"

using Distributed, .Threads

include("interface.jl")
include("types.jl")
include("messages.jl")
include("links.jl")
include("com.jl")
include("actor.jl")
include("protocol.jl")
include("task.jl")
include("api.jl")
include("registry.jl")
include("init.jl")
include("diag.jl")

export  
    # common types
    Msg, Request, Response, Link, Func,
    # -------------------------------
    # exported interface primitives
    send!,  
    # the following ones must be imported explicitly:
    # - newLink, 
    # - spawn,
    # - _ACT,
    # - onmessage
    # -------------------------------
    # API primitives
    receive!, request!,
    # API
    Args, become, self, stop,
    become!, call!, cast!, exec!, exit!, init!, 
    query!, update!,
    # Tasks
    ATask, async, await,
    # Registry
    register, unregister, whereis, registered
    
end