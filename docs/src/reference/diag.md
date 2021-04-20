# Diagnostics

```@meta
CurrentModule = Actors
```

`Actors` are represented only by their [`Link`](@ref)s. There are two API functions: [`info`](@ref) and [`diag`](@ref) (the latter is not exported) to get more information about them.

## Actor Identification

Actors can be identified by their task's address. On a common 64-bit machine this is a `UInt64` number. To improve readability `Actors` shows this number encoded as a [Proquint](https://github.com/pbayer/Proquint.jl) string (short form):

```julia
julia> sv = supervisor()
Link{Channel{Any}}(Channel{Any}(sz_max:32,sz_curr:0), 1, :supervisor)

julia> info(sv)
Actor    supervisor
Behavior Actors.Supervisor
Pid      1, Thread 2
Task     @0x0000000120c16890
Ident    x-d-fagad-kofib

julia> Actors.diag(sv, :task)
Task (runnable) @0x0000000120c16890

julia> Actors.diag(sv, :tid)
"x-d-fagad-kofib"

julia> exit!(sv, :shutdown);
┌ Warning: 2021-02-05T12:51:33.288 x-d-fagad-kofib: Exit: supervisor shutdown
└ @ Actors ~/.julia/dev/Actors/src/logging.jl:30

julia> using Proquint

julia> quint2uint("x-d-fagad-kofib")
0x0000000120c16890
```

## Status Information

For testing and diagnosis you can use [`diag`](@ref) to get status information from an actor. For example `diag(x, :act)` returns the actors' `x` status variable:

```julia
julia> myact = spawn(threadid)
Link{Channel{Any}}(Channel{Any}(sz_max:32,sz_curr:0), 1, :default)

julia> myact_state = Actors.diag(myact, :act)
Actors._ACT(:default, Base.Threads.threadid, nothing, nothing, Link{Channel{Any}}(Channel{Any}(sz_max:32,sz_curr:0), 1, :default), nothing, nothing, nothing, nothing, Actors.Connection[])
```

But since an actors' state is private, this should be used for diagnostic purposes only.
