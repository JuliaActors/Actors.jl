#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#
"""
`Actors` implements the classical Actor Model and is 
based on the primitives defined in `ActorInterfaces.Classic`. 
It provides:

- basic primitives for creating actors,
    sending messages to them and changing behavior:
    [`spawn`](@ref), [`send`](@ref), [`become`](@ref) 
    with `Addr` and [`self`](@ref),
- [`onmessage`](@ref), executed by an actor on a 
    received message,
- a `Msg` message protocol with `onmessage` and 
    predefined messages,
- an actor API based on the protocol with primitives
    [`receive`](@ref) and [`request`](@ref) and further 
    API functions [`become!`](@ref), [`call`](@ref), 
    [`cast`](@ref), [`exec`](@ref), [`exit!`](@ref), 
    [`init!`](@ref), [`query`](@ref), [`term!`](@ref), 
    [`update!`](@ref),
- actor tasks with [`async`](@ref) and [`await`](@ref),
- an actor registry and more.

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
const version = v"0.2.3"

using ActorInterfaces.Classic
using Distributed, .Threads, Dates
import ActorInterfaces.Classic: onmessage

include("types.jl")
include("messages.jl")
include("links.jl")
include("com.jl")
include("connections.jl")
include("errorkernel.jl")
include("protocol.jl")
include("actor.jl")
include("task.jl")
include("api.jl")
include("registry.jl")
include("init.jl")
include("diag.jl")
include("utils.jl")

export  
    # common types
    Msg, @msg, Request, Response, Link, Bhv,
    # -------------------------------
    # exported interface primitives
    send,  
    # the following ones must be imported explicitly:
    # - newLink, 
    # - spawn,
    # - _ACT,
    # - onmessage
    # -------------------------------
    # API primitives
    receive, request,
    # API
    Args, become, self, stop,
    become!, call, cast, exec, exit!, init!, 
    query, term!, update!,
    # Tasks
    ATask, async, await,
    # Registry
    register, unregister, whereis, registered,
    # Supervision
    connect, disconnect, monitor, demonitor, trapExit
    
end