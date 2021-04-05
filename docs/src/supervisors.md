# Supervisors

```@meta
CurrentModule = Actors
```

A supervisor is an actor looking after child actors and restarting them as necessary when they exit. We setup a supervisor  `A10` with six child actors `A1`-`A6`:

```julia
julia> A10 = supervisor()  # start supervisor A10 with default strategy :one_for_one
Link{Channel{Any}}(Channel{Any}(32), 1, :supervisor)

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

We let `A1`-`A6` be [`supervise`](@ref)d by `A10` with default arguments. Thus they are restarted with their `threadid` behavior and they are assumed to be `:transient` (they get restarted if they terminate abnormally).

## Restart Strategies

Our system now looks similar to the following:

![supervisor](assets/supervisor.svg)

Now, what the supervisor `A10` does if one of its children – say `A4` - exits abnormally, is determined by its supervision strategy and by the child's restart variable and exit reason.

| strategy | brief description |
|:---------|:------------------|
| `:one_for_one` | only the terminated actor is restarted (`A4`), |
| `:one_for_all` | all other child actors are terminated, then all child actors are restarted (`A1`-`A6`), |
| `:rest_for_one` | the children started after the terminated one are terminated, then all terminated ones are restarted (`A4`-`A6`). |

With the default supervision strategy `:one_for_one` only the failed actor gets restarted:

```julia
julia> send(A[4], :boom);                   # let A4 fail
┌ Warning: 2021-02-13 12:55:27 x-d-kuhub-dabab: Exit: supervised Task (failed) @0x000000016e949bb0, MethodError(Base.Threads.threadid, (:boom,), 0x0000000000007458)
└ @ Actors ~/.julia/dev/Actors/src/logging.jl:31
┌ Warning: 2021-02-13 12:55:27 x-d-kuhub-dabab: supervisor: restarting
└ @ Actors ~/.julia/dev/Actors/src/logging.jl:31

julia> t = map(a->Actors.diag(a, :task), A) # A1-A6 have runnable tasks, but A4 has been restarted
6-element Vector{Task}:
 Task (runnable) @0x000000016e948560
 Task (runnable) @0x000000016e949660
 Task (runnable) @0x000000016e949880
 Task (runnable) @0x000000010e3b8230
 Task (runnable) @0x000000016e949ee0
 Task (runnable) @0x000000016e94a100
```

With the second strategy `:one_for_all`, all supervised actors/tasks get restarted if one of them fails. That allows to restart a group of equitable actors depending on each other.

```julia
julia> set_strategy(A10, :one_for_all)      # change restart strategy
(Actors.Strategy(:one_for_all),)

julia> send(A[4], :boom);                   # let A4 fail again
┌ Warning: 2021-02-13 12:57:16 x-d-kuhub-dabab: Exit: supervised Task (failed) @0x000000010e3b8230, MethodError(Base.Threads.threadid, (:boom,), 0x0000000000007459)
└ @ Actors ~/.julia/dev/Actors/src/logging.jl:31
┌ Warning: 2021-02-13 12:57:16 x-d-kuhub-dabab: supervisor: restarting all
└ @ Actors ~/.julia/dev/Actors/src/logging.jl:31

julia> t = map(a->Actors.diag(a, :task), A) # all actors have been restarted (got new tasks)
6-element Vector{Task}:
 Task (runnable) @0x000000010e3b8450
 Task (runnable) @0x000000010e3b8670
 Task (runnable) @0x000000010e3b8890
 Task (runnable) @0x000000010e3b8ab0
 Task (runnable) @0x000000010e3b8cd0
 Task (runnable) @0x000000010e3b9000
```

With `:rest_for_one` only the failed actor and the actors that registered for supervision after it are restarted. That allows to restart a failed actor and only those other actors depending on it:

```julia
julia> set_strategy(A10, :rest_for_one)     # change strategy again
(Actors.Strategy(:rest_for_one),)

julia> send(A[4], :boom);                   # let A4 fail
┌ Warning: 2021-02-13 12:58:33 x-d-kuhub-dabab: Exit: supervised Task (failed) @0x000000010e3b8ab0, MethodError(Base.Threads.threadid, (:boom,), 0x000000000000745a)
└ @ Actors ~/.julia/dev/Actors/src/logging.jl:31
┌ Warning: 2021-02-13 12:58:33 x-d-kuhub-dabab: supervisor: restarting rest
└ @ Actors ~/.julia/dev/Actors/src/logging.jl:31

julia> t = map(a->Actors.diag(a, :task), A) # A4 - A6 have been restarted
6-element Vector{Task}:
 Task (runnable) @0x000000010e3b8450
 Task (runnable) @0x000000010e3b8670
 Task (runnable) @0x000000010e3b8890
 Task (runnable) @0x000000010e3b9220
 Task (runnable) @0x000000010e3b9440
 Task (runnable) @0x000000010e3b9770
```

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

## Child restart options

Child restart options with supervise allow for finer child-specific control of restarting:

| restart option | brief description |
|:---------------|:------------------|
| `:permanent` |  the child actor is always restarted, |
| `:temporary` | the child is never restarted, regardless of the supervision strategy, |
| `:transient` | the child is restarted only if it terminates abnormally, i.e., with an exit reason other than `:normal` or `:shutdown`. |

## Supervisor API

Supervisors allow some automation and control of error handling in an actor system. They have the following API:

| API function | brief description |
|:-------------|:------------------|
| [`supervisor`](@ref) | start a supervisor actor, |
| [`supervise`](@ref) | add the current actor to a supervisor's child list, |
| [`unsupervise`](@ref) | delete the current actor from a supervisor's child list, |
| [`start_actor`](@ref) | tell a supervisor to start an actor as a child, |
| [`start_task`](@ref) | tell a supervisor to start a task as a child, |
| [`delete_child`](@ref) | tell a supervisor to remove an actor from its child list, |
| [`terminate_child`](@ref) | tell a supervisor to terminate a child and to remove it from its child list, |
| [`set_strategy`](@ref) | tell a supervisor to change its supervision strategy, |
| [`count_children`](@ref) | tell a supervisor to return a children count, |
| [`which_children`](@ref) | tell a supervisor to return a list of its children. |

With options we can limit how often a supervisor tries to restart children in a given timeframe. If it exceeds this limit, it terminates itself and all of its children with a warning.

## Actor State Across Restarts

By default a supervisor restarts an actor with the behavior and acquaintances it had before exiting or shutdown. An actor thus maintains its state over a restart:

```julia
julia> incr(x, by=0) = x[end] += by       # define an accumulator
incr (generic function with 2 methods)

julia> myactor = spawn(incr, [10])        # start an actor accumulating from 10
Link{Channel{Any}}(Channel{Any}(32), 1, :default)

julia> exec(myactor, supervise, sv)       # put it under supervision
(Actors.Child{Link{Channel{Any}}}(Link{Channel{Any}}(Channel{Any}(32), 1, :default), nothing, :transient),)

julia> foreach(x->call(myactor, x), 1:10) # accumulate

julia> send(myactor, :boom);              # let it fail
┌ Warning: 2021-02-13 12:58:37 x-d-kuhub-dabab: Exit: supervised Task (failed) @0x000000016e4cb200, MethodError(+, (65, :boom), 0x00000000000073ef)
└ @ Actors ~/.julia/dev/Actors/src/logging.jl:31
┌ Warning: 2021-02-13 12:58:37 x-d-kuhub-dabab: supervisor: restarting
└ @ Actors ~/.julia/dev/Actors/src/logging.jl:31

julia> call(myactor)                      # it has maintained its state
65
```

!!! note "Actor state recovery after node failures is different!"
    In case of a [node failure](node_failures.md) an actor cannot send its state at failure time to the supervisor. In those cases you can use termination and restart callbacks and [checkpointing](checkpoints.md) for recovery.

## Termination and Restart Callbacks

There are cases where you want a different user-defined fallback strategy for actor restart, for example to

- restart it with a different algorithm/behavior or data set or
- do some cleanup before restarting it,
- restart after a node failure,
- save and restore a checkpoint.

For that you can define callback functions invoked at actor termination, restart or initialization:

| callback | short description |
|:---------|:------------------|
| [`term!`](@ref) | `term` callback; if defined, it is called at actor exit with argument `reason` (exit reason), |
| `restart` | a given `cb` argument to [`supervise`](@ref), [`start_actor`](@ref) or [`start_task`](@ref) is executed by a supervisor to restart an actor/task; |
| [`init!`](@ref) | if defined (and no `restart` callback is given), the supervisor restarts an actor with the given `init` behavior. |

User defined callbacks must follow some conventions:

1. A `restart` callback does some initialization and spawns an actor or a task and returns a [`Link`](@ref) or a `Task` which  again will be supervised.
2. An `init` callback is a startup *behavior* of an actor. It does some initialization or recovery and then switches (with [`become`](@ref)) to the target behavior. A supervisor spawns a new supervised actor with the given `init` behavior and triggers it with `init()`.
3. A supervisor wants an actor running on a worker process (over a `RemoteChannel`) to restart on the same or on a spare `pid` (process id). In that case it calls the `restart` callback with a `pid` keyword argument (and the callback must take it).

## Preserving actor links after restart

After restarting an actor, a supervisor updates its link to point to the newly created actor. But existing copies of a link won't get updated and may then be out of sync.

If remote actors on other workers communicate with an actor over `RemoteChannel`s, they have copies of its link on their workers. After actor restart those are out of sync, and a remote actor may try to communicate with an old failed actor. To avoid this situation, you should [`register`](@ref) those actors and use their registered name to supervise them and communicate with them. The supervisor then will update the registered link.

## Task Supervision

## Supervisory trees

Often you may be interested in building a hierarchical structure containing all actors and tasks in your application. This is called a supervisory tree, and there is the [`Supervisors`](https://github.com/JuliaActors/Supervisors.jl) package facilitating to build that.
