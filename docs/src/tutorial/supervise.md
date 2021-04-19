# Supervise Actors

```@meta
CurrentModule = Actors
```

A supervisor is an actor looking after child actors and restarting them as necessary when they exit.

## Setup a supervisor

We setup a [`supervisor`](@ref) `A10` with the default [supervision strategy](@ref strategies) `:one_by_one`:

```julia
julia> using Actor, .Threads

julia> import Actors: spawn

julia> A10 = supervisor()
Link{Channel{Any}}(Channel{Any}(32), 1, :supervisor)
```

## Supervise child actors

We start six actors `A1`-`A6` and [`supervise`](@ref) them with `A10` with default [restart arguments](@ref restart). If they fail, they will be restarted with their `threadid` behavior and  are assumed to be `:transient` (they get restarted if they terminate abnormally).

```julia
julia> A = map(_->spawn(threadid), 1:6);    # spawn A1 - A6

julia> t = map(a->Actors.diag(a, :task), A) # A1 - A6 are running
6-element Vector{Task}:
 Task (runnable) @0x000000016e948560
 Task (runnable) @0x000000016e949660
 Task (runnable) @0x000000016e949880
 Task (runnable) @0x000000016e949bb0
 Task (runnable) @0x000000016e949ee0
 Task (runnable) @0x000000016e94a100

julia> foreach(a->exec(a, supervise, A10), A)
```

**One for one**: With the default supervision strategy `:one_for_one` the supervisor restarts a single actor when it fails:

```julia
julia> send(A[4], :boom);                   # let A4 fail
┌ Warning: 2021-02-13 12:55:27 x-d-kuhub-dabab: Exit: supervised Task (failed) @0x000000016e949bb0, MethodError(Base.Threads.threadid, (:boom,), 0x0000000000007458)
└ @ Actors ~/.julia/dev/Actors/src/logging.jl:31
┌ Warning: 2021-02-13 12:55:27 x-d-kuhub-dabab: supervisor: restarting
└ @ Actors ~/.julia/dev/Actors/src/logging.jl:31

julia> t = map(a->Actors.diag(a, :task), A) # look at the tasks
6-element Vector{Task}:
 Task (runnable) @0x000000016e948560
 Task (runnable) @0x000000016e949660
 Task (runnable) @0x000000016e949880
 Task (runnable) @0x000000010e3b8230
 Task (runnable) @0x000000016e949ee0
 Task (runnable) @0x000000016e94a100
```

A1-A6 have all runnable tasks, but A4 has been restarted.

**One for all**: With the second strategy `:one_for_all`, all supervised actors/tasks get restarted if one of them fails. That allows to restart a group of equitable actors depending on each other. Normally we would choose the strategy at supervisor start, but now we change the supervision strategy of the running supervisor A10 and let A4 fail again:

```julia
julia> set_strategy(A10, :one_for_all)      # change restart strategy
(Actors.Strategy(:one_for_all),)

julia> send(A[4], :boom);                   # let A4 fail again
┌ Warning: 2021-02-13 12:57:16 x-d-kuhub-dabab: Exit: supervised Task (failed) @0x000000010e3b8230, MethodError(Base.Threads.threadid, (:boom,), 0x0000000000007459)
└ @ Actors ~/.julia/dev/Actors/src/logging.jl:31
┌ Warning: 2021-02-13 12:57:16 x-d-kuhub-dabab: supervisor: restarting all
└ @ Actors ~/.julia/dev/Actors/src/logging.jl:31

julia> t = map(a->Actors.diag(a, :task), A)
6-element Vector{Task}:
 Task (runnable) @0x000000010e3b8450
 Task (runnable) @0x000000010e3b8670
 Task (runnable) @0x000000010e3b8890
 Task (runnable) @0x000000010e3b8ab0
 Task (runnable) @0x000000010e3b8cd0
 Task (runnable) @0x000000010e3b9000
```

All actors have been restarted (got new tasks).

**Rest for one**: With `:rest_for_one` only the failed actor and the actors that registered for supervision after it are restarted. That allows to restart a failed actor and only those other actors depending on it. Again we change A10's strategy and let A4 fail:

```julia
julia> set_strategy(A10, :rest_for_one)     # change strategy again
(Actors.Strategy(:rest_for_one),)

julia> send(A[4], :boom);                   # let A4 fail
┌ Warning: 2021-02-13 12:58:33 x-d-kuhub-dabab: Exit: supervised Task (failed) @0x000000010e3b8ab0, MethodError(Base.Threads.threadid, (:boom,), 0x000000000000745a)
└ @ Actors ~/.julia/dev/Actors/src/logging.jl:31
┌ Warning: 2021-02-13 12:58:33 x-d-kuhub-dabab: supervisor: restarting rest
└ @ Actors ~/.julia/dev/Actors/src/logging.jl:31

julia> t = map(a->Actors.diag(a, :task), A)
6-element Vector{Task}:
 Task (runnable) @0x000000010e3b8450
 Task (runnable) @0x000000010e3b8670
 Task (runnable) @0x000000010e3b8890
 Task (runnable) @0x000000010e3b9220
 Task (runnable) @0x000000010e3b9440
 Task (runnable) @0x000000010e3b9770
```

Now A4 - A6 have been restarted.

### Further options

With further [`supervisor`](@ref) options we can limit how often a supervisor tries to restart children in a given timeframe. If it exceeds this limit, it terminates itself and all of its children with a warning.

## Query failed actors

For all failures we got warnings, but we can query the last failures from the supervisor and get more information about them:

```julia
julia> failed = Actors.diag(A10, :err)      # the three failed tasks can be queried from the supervisor
3-element Vector{Task}:
 Task (failed) @0x000000016e949bb0
 Task (failed) @0x000000010e3b8230
 Task (failed) @0x000000010e3b8ab0

julia> failed[1]                            # exceptions and stacktraces are available
Task (failed) @0x000000016e949bb0
MethodError: no method matching threadid(::Symbol)
....
```

## Maintain actor state across restarts

By default a supervisor restarts an actor with the behavior it had before exiting. An actor thus maintains its state over a restart:

```julia
julia> sv = supervisor()
Link{Channel{Any}}(Channel{Any}(32), 1, :supervisor)

julia> incr(xr, by=0) = xr[] += by        # define an accumulator
incr (generic function with 2 methods)

julia> myactor = spawn(incr, Ref(10))     # start an actor accumulating from 10
Link{Channel{Any}}(Channel{Any}(32), 1, :default)

julia> exec(myactor, supervise, sv);      # put it under supervision

julia> foreach(x->call(myactor, x), 1:10) # accumulate it

julia> call(myactor)
65

julia> send(myactor, :boom);              # let it fail
┌ Warning: 2021-04-19 17:00:17 x-d-kolok-ib Exit: supervised Task (failed) @0x000000016b9d4010, MethodError(+, (65, :boom), 0x00000000000074aa)
└ @ Actors ~/.julia/dev/Actors/src/logging.jl:39
┌ Warning: 2021-04-19 17:00:17 x-d-kolok-ib supervisor: restarting
└ @ Actors ~/.julia/dev/Actors/src/logging.jl:39

julia> call(myactor)
65

julia> info(myactor)
Actor    default
Behavior incr
Pid      1, Thread 1
Task     @0x000000016da2ba80
Ident    x-d-kukof-ropab
```

`myactor` has maintained its state over failure even if it got a new task.

!!! note "Actor state recovery after node failures is different!"
    In case of a [node failure](../manual/node_failures.md) an actor cannot send its state at failure time to the supervisor. In those cases you can use termination and restart callbacks and [checkpointing](../manual/checkpoints.md) for recovery.
