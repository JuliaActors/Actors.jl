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
- a message protocol with predefined messages,
- an API based on the protocol with primitives
    [`receive`](@ref) and [`request`](@ref) and further 
    API functions [`become!`](@ref), [`call`](@ref), 
    [`cast`](@ref), [`exec`](@ref), [`exit!`](@ref), 
    [`init!`](@ref), [`query`](@ref), [`term!`](@ref), 
    [`update!`](@ref),
- error handling with actor
    - connections: [`connect`](@ref), [`disconnect`](@ref), [`trapExit`](@ref),
    - monitors: [`monitor`](@ref), [`demonitor`](@ref),
    - supervisors: [`supervisor`](@ref), [`supervise`](@ref), 
        [`unsupervise`](@ref), [`start_actor`](@ref), 
        [`start_task`](@ref), [`count_children`](@ref), 
        [`which_children`](@ref), [`terminate_child`](@ref), 
- an actor registry: [`register`](@ref), [`unregister`](@ref), 
    [`whereis`](@ref), [`registered`](@ref)

and more.

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
const version = v"0.2.5"

using ActorInterfaces.Classic
using Distributed, .Threads, Serialization, Dates, Proquint
import ActorInterfaces.Classic: onmessage
import Base: structdiff

include("types.jl")
include("messages.jl")
include("links.jl")
include("com.jl")
include("connections.jl")
include("logging.jl")
include("errorkernel.jl")
include("supervisor.jl")
include("remote_failures.jl")
include("checkpoints.jl")
include("protocol.jl")
include("actor.jl")
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
    receive, request, send_after,
    # API
    Args, become, self, stop,
    become!, call, cast, exec, exit!, info, init!, 
    query, term!, update!,
    # registry
    register, unregister, whereis, registered,
    # error handling
    connect, disconnect, monitor, demonitor, trapExit,
    # supervising
    supervisor, supervise, unsupervise, 
    set_strategy, count_children, which_children,
    delete_child, start_actor, start_task, terminate_child,
    # checkpointing
    checkpointing, checkpoint, restore, get_checkpoints,
    save_checkpoints, load_checkpoints, @chkey

end
