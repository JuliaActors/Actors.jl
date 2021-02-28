#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#

# messages
struct Checkpoint{T,L}
    level::Int
    key::Symbol
    var::T
    from::L
end
struct Interval{T}
    x::T
end
struct Load
    from::AbstractString
end
struct Register{L}
    lk::L
end
struct Parent{L}
    lk::L
end
struct Reset 
    key::Symbol
end
struct Restore{L}
    level::Int
    key::Symbol
    from::L
end
struct Save end
struct Snapshot end
struct Start end
struct Stop end

# Checkpointing actor
mutable struct Checkpointing{S,T}
    store::S
    level::Int
    file::AbstractString
    parent::Union{Link,Nothing}
    children::Vector{Link}
    interval::T
    timer::Vector{Timer}
end

function (cp::Checkpointing)(msg::Checkpoint)
    cp.store[msg.key] = msg.var
    if cp.level < msg.level && !isnothing(cp.parent)
        send(cp.parent, Checkpoint(msg.level, msg.key, msg.var, self()))
    elseif cp.level ≥ 2
        foreach(cp.children) do child
            if child != msg.from
                foreach(call(child)) do check
                    cp.store[check[1]] = check[2]
                end
            end
        end
    end
end
function (cp::Checkpointing)(msg::Interval)
    cp.interval = msg.x
    foreach(close, cp.timer)
    empty!(cp.timer)
    cp.interval.on && cp(Start())
end
function (cp::Checkpointing)(msg::Load)
    !isempty(cp.file) && open(msg.from, "r") do io
        cp.store = deserialize(io)
    end
end
(cp::Checkpointing)(msg::Parent) = cp.parent = msg.lk
(cp::Checkpointing)(msg::Register) = unique!(push!(cp.children, msg.lk))
function (cp::Checkpointing)(msg::Reset)
    msg.key == :all ?
        empty!(cp.store) :
        delete!(cp.store, msg.key)
end
function (cp::Checkpointing)(msg::Restore)
    if cp.level ≤ msg.level || isempty(cp.parent)
        send(msg.from, get(cp.store, msg.key, nothing))
    else
        send(cp.parent, msg) # propagate upwards
    end
end
function (cp::Checkpointing)(::Save)
    !isempty(cp.file) && open(cp.file, "w") do io
        serialize(io, cp.store)
    end
end
function (cp::Checkpointing)(::Start)
    !cp.interval.on && (cp.interval = merge(cp.interval, (; on=true)))
    if cp.interval.update ≥ 1
        push!(cp.timer, Timer(0, interval=cp.interval.update) do timer
            send(self(), Update())
        end)
    end
    if cp.interval.save ≥ 1 && !isempty(cp.file)
        push!(cp.timer, Timer(0, interval=cp.interval.save) do timer
            send(self(), Save())
        end)
    end
end
function (cp::Checkpointing)(::Stop)
    cp.interval = merge(cp.interval, (; on=false))
    foreach(close, cp.timer)
    empty!(cp.timer)
end
function (cp::Checkpointing)(::Snapshot)
    if cp.level ≥ 2
        foreach(cp.children) do child
            foreach(call(child)) do check
                cp.store[check[1]] = check[2]
            end
        end
    end
end
(cp::Checkpointing)() = cp.store 

# Checkpointing API
"""
    checkpointing(level=1, filename::AbstractString=""; kwargs...)

Start a checkpointing actor and return a [`Link`](@ref) to it.

# Arguments
- `filename::AbstractString`: filename where the actor should save its
    checkpointing buffer,
- `on::Bool=false`: should checkpoints automatically be updated and saved, 
- `update::Int=10`: update interval in seconds ≥ 1,
- `save::Int=60`: saving interval in seconds ≥ 1,
- `kwargs...`: keyword arguments to [`spawn`](@ref).

!!! note
    Updating or saving is only done automatically if their
    intervals are ≥ 1 seconds.
"""
function checkpointing(level::Int=1 ,filename::AbstractString=""; 
                        on::Bool=false, update::Int=10, save::Int=60, kwargs...)
    cp = spawn(Checkpointing(Dict{Symbol, Any}(), 
                             level, filename, nothing, Link[],
                             (; on, update, save), Timer[]); 
            kwargs...)
    on && send(cp, Start())
    return cp
end

"""
    @chkey a b c 123

Build a checkpointing key from the surrounding module and function
names and the given arguments. This is intended for easy construction
of checkpointing keys.

# Example
```julia
module MyModule

using Actors

function mykey()
    a = 1
    b = 2
    c = 3
    # do something
    return @chkey a b c 123
end

export mykey
end # MyModule

julia> using .MyModule

julia> mykey()
:MyModule_mykey_a_b_c_123
```
"""
macro chkey(exs...)
    return quote
        st = stacktrace(backtrace())
        func = +
        for frm in st
            if frm.func != :backtrace && frm.func != Symbol("macro expansion")
                func = frm.func
                break
            end
        end
        ret = Symbol($(__module__),"_",func)
        for ex in $exs
            ret = Symbol(ret, "_", sprint(Base.show_unquoted, ex))
        end
        ret
    end
end

"""
    checkpoint(cp::Link, key::Symbol, args...)

Tell a checkpointing actor to take a checkpoint.

# Arguments
- `cp::Link`: [`Link`](@ref) to the checkpointing actor,
- `key::Symbol`: key for the checkpoint,
- `args...`: variables to save in the checkpoint,
- `level::Int=1`: checkpoint level.
"""
checkpoint(cp::Link, key::Symbol, args...; level::Int=1) = 
    send(cp, Checkpoint(level, key, args, nothing))

"""
    restore(cp::Link; key::Symbol)

Tell a checkpointing actor to restore the last taken checkpoint.

# Arguments
- `cp::Link`:  [`Link`](@ref) to the checkpointing actor,
- `key::Symbol`: checkpoint key,
- `level::Int=1`: checkpoint level to restore from.
"""
function restore(cp::Link, key::Symbol; level::Int=1)
    me = newLink()
    send(cp, Restore(level, key, me))
    return receive(me)
end

"Tell the checkpointing actor `cp` to return its stored checkpoint data."
get_checkpoints(cp::Link) = call(cp)

"Tell a checkpointing actor `cp` to save its stored checkpoint data."
save_checkpoints(cp::Link) = send(cp, Save())

"Tell a checkpointing actor `cp` to load checkpointing data from a file"
load_checkpoints(cp::Link, fromfile::AbstractString) = send(cp, Load(fromfile)) 

"""
    set_interval(cp::Link; kwargs...)

Set the checkpointing intervals of a checkpointing actor `cp`.

# Arguments
- `cp::Link`: [`Link`](@ref) to a checkpointing actor,
- `kwargs...`: allowed keyword arguments:
    - `on:Bool`: should checkpoints automatically be updated and saved,
    - `update::Int`: update interval in seconds ≥ 1,
    - `save::Int`: saving interval in seconds ≥ 1.
"""
function set_interval(cp::Link; kwargs...)
    intv = get_interval(cp)
    kw = NamedTuple(kwargs)
    res = merge(interval, kw)
    typeof(res) == typeof(interval) ? 
        send(cp, Interval(res)) : 
        throw(AssertionError("forbidden key/value in $kw"))
end

"""
Get the checkpointing intervals of a checkpointing actor.
"""
get_interval(cp::Link) = diag(cp, :bhv).interval

"""
Register a checkpointing actor to a higher level actor.
"""
register_checkpoint(cp::Link) = send(cp, Register(self()))

"""
Start periodic checkpointing.
"""
start_checkpointing(cp::Link) = send(cp, Start())

"""
Stop periodic checkpointing.
"""
stop_checkpointing(cp::Link) = send(cp, Stop())
