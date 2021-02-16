#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#

# messages
struct Checkpoint{T}
    key::String
    vars::T
end
struct Restore 
    key::String
end
struct Save end
struct Reset 
    key::String
end
struct Load
    from::String
end

# Checkpointing actor
mutable struct Checkpointing{S}
    store::S
    buffer::Int
    file::String
end

function (cp::Checkpointing)(msg::Checkpoint)
    buf = get!(cp.store, msg.key, Vector{typeof(msg.vars)}())
    length(buf) ≥ cp.buffer && popfirst!(buf)
    push!(buf, msg.vars)
end
function (cp::Checkpointing)(msg::Restore)
    buf = get(cp.store, msg.key, nothing)
    return isnothing(buf) ? nothing :
        isempty(buf) ? nothing : last(buf)
end
function (cp::Checkpointing)(::Save)
    open(cp.file, "w") do io
        serialize(io, cp.store)
    end
end
function (cp::Checkpointing)(msg::Load)
    open(msg.from, "r") do io
        cp.store = deserialize(io)
    end
end
function (cp::Checkpointing)(msg::Reset)
    if !isempty(msg.key)
        buf = get(cp.store, msg.key, nothing)
        !isnothing(buf) && empty!(buf)
    else
        empty!(cp.store)
    end
end
(cp::Checkpointing)() = cp.store 

# Checkpointing API
"""
    checkpointing(filename::String, buffer::Int=10; kwargs...)

Start a checkpointing actor and return a [`Link`](@ref) to it.

# Arguments
- `filename::String`: filename where the actor should save its
    checkpointing buffer,
- `buffer::Int=10`: buffersize for number of checkpoints per key,
- `kwargs...`: keyword arguments to [`spawn`](@ref) the actor.
"""
function checkpointing(filename::String, buffer::Int=10; kwargs...)
    spawn(Checkpointing(Dict{String, Vector{T} where T}(), buffer, filename); kwargs...)
end

"""
    checkpoint(cp::Link, key::String, args...)

Tell a checkpointing actor to take a checkpoint.

# Arguments
- `cp::Link`: [`Link`](@ref) to the checkpointing actor,
- `key::String`: a key for checkpointing buffer,
- `args...`: variables to save in the checkpointing buffer.
"""
checkpoint(cp::Link, key::String, args...) = send(cp, Checkpoint(key, args))

"""
    restore(cp::Link; key::String)

Tell a checkpointing actor to restore the last taken checkpoint.

# Arguments
- `cp::Link`:  [`Link`](@ref) to the checkpointing actor,
- `key::String`: checkpoint key.
"""
restore(cp::Link, key::String) = call(cp, Restore(key))

"""
Tell the checkpointing actor `cp` to return its stored checkpoint
data.
"""
get_checkpoints(cp::Link) = call(cp)

"Tell a checkpointing actor `cp` to save its stored checkpoint data."
save_checkpoints(cp::Link) = send(cp, Save())

"Tell a checkpointing actor cp to load checkpointing data from a file"
load_checkpoints(cp::Link, fromfile::String) = send(cp, Load(fromfile)) 
