# Error Handling

```@meta
CurrentModule = Actors
```

`Actors` provides Erlang/OTP-like [^1][^2] mechanisms and message protocols to

1. handle errors in actors and tasks and to
2. write fault-tolerant programs.

The basic philosophy is not to defend against errors but to detect them and then to take action about them. There are two basic mechanisms for that: *connections* and *monitors*:

## Connections

If you [`connect`](@ref) actors, they send each other [`Exit`](@ref) messages when they fail, [`stop`](@ref) or [`exit!`](@ref). An actor propagates an `Exit` message to all its connected actors and then terminates

- if the exit reason is other than `:normal`,
- and if it is not `:sticky`.

With [`trapExit`](@ref) an actor can be made `:sticky`. When it then receives an `Exit` message with a reason other than `:normal`, it will

- not propagate it and not terminate but
- give a warning about it and
- store a link to the failed actor.

Connections between actors are always bidirectional and can be [`disconnect`](@ref)ed. You can build a chain or network of connected actors that depend on each other and exit together. A `:sticky` actor operates as a firewall among connected actors.

![connection](assets/connect.svg)

Assume in an actor system `A1`-`A3`-`A7`-`A9`-`A4` are connected, `A3` is a `:sticky` actor and `A9` fails. Before it terminates, it sends an `Exit` message to `A4` and `A7`. `A7` propagates it further to `A3`. `A9`, `A4` and `A7` die together. `A3` gives a warning about the failure and saves the link to the failed actor `A9`. `A3` does not propagate the `Exit` to `A1`. Both `A1` and `A3` stay connected and continue to operate. The other actors are separate and are not affected by the failure. This is illustrated in the following script:

```julia
julia> using Actors, .Threads

julia> import Actors: spawn

julia> A = map((_)->spawn(threadid), 1:10); # create 10 actors

julia> exec(A[3], connect, A[1]);           # connect A3 - A1

julia> exec(A[3], connect, A[7]);           # connect A3 - A7

julia> exec(A[9], connect, A[7]);           # connect A9 - A7

julia> exec(A[9], connect, A[4]);           # connect A9 - A4

julia> t = map(a->Actors.diag(a, :task), A) # create a task list
10-element Vector{Task}:
 Task (runnable) @0x000000016e949220
 Task (runnable) @0x000000016e94a100
 Task (runnable) @0x000000016e94a320
 Task (runnable) @0x000000016e94a540
 Task (runnable) @0x000000016e94a760
 Task (runnable) @0x000000016e94a980
 Task (runnable) @0x000000016e94aba0
 Task (runnable) @0x000000016e94adc0
 Task (runnable) @0x000000016e94b0f0
 Task (runnable) @0x000000016e94b310

julia> trapExit(A[3])                       # make A3 a sticky actor
Actors.Update(:mode, :sticky)

julia> send(A[9], :boom);                   # cause A9 to fail
┌ Warning: 2021-02-13 12:08:11 x-d-kupih-pasob: Exit: connected Task (failed) @0x000000016e94b0f0, MethodError(Base.Threads.threadid, (:boom,), 0x0000000000007447)
└ @ Actors ~/.julia/dev/Actors/src/logging.jl:31

julia> t                                    # display the task list again
10-element Vector{Task}:
 Task (runnable) @0x000000016e949220
 Task (runnable) @0x000000016e94a100
 Task (runnable) @0x000000016e94a320
 Task (done) @0x000000016e94a540
 Task (runnable) @0x000000016e94a760
 Task (runnable) @0x000000016e94a980
 Task (done) @0x000000016e94aba0
 Task (runnable) @0x000000016e94adc0
 Task (failed) @0x000000016e94b0f0
 Task (runnable) @0x000000016e94b310
```

## Monitors

An actor can be told to [`monitor`](@ref) other actors or Julia tasks. Monitored actors or tasks send a [`Down`](@ref) message with an exit reason to their monitor(s) before they terminate. A monitor then gives a warning or executes a specified action dispatched on the received reason.

![monitor](assets/monitor.svg)

`A3` is a monitor. It gets a `Down` signal from its monitored actors if they exit.

```julia
julia> A = map(_->spawn(threadid), 1:3);

julia> exec(A[3], monitor, A[1]);

julia> exec(A[3], monitor, A[2]);

julia> t = map(a->Actors.diag(a, :task), A)
3-element Vector{Task}:
 Task (runnable) @0x000000010f8f5000
 Task (runnable) @0x000000010fbb8120
 Task (runnable) @0x000000010fbb8890

julia> exit!(A[1]);
┌ Warning: 2021-02-13 12:36:32 x-d-uvur-mofib: Down:  normal
└ @ Actors ~/.julia/dev/Actors/src/logging.jl:31

julia> send(A[2], :boom);
┌ Warning: 2021-02-13 12:36:58 x-d-uvur-mofib: Down:  Task (failed) @0x000000010fbb8120, MethodError(Base.Threads.threadid, (:boom,), 0x000000000000744f)
└ @ Actors ~/.julia/dev/Actors/src/logging.jl:31

julia> t
3-element Vector{Task}:
 Task (done) @0x000000010f8f5000
 Task (failed) @0x000000010fbb8120
 Task (runnable) @0x000000010fbb8890
```

Monitors do not forward `Down` messages. They give warnings or execute specified actions for `Down` signals (even with reason `:normal`). Monitoring is not bidirectional. If a monitor fails, the monitored actor gets no notification. Monitoring can be stopped with [`demonitor`](@ref). An actor can have several monitors (if that makes sense).

## Supervisors

A supervisor is an actor looking after child actors and restarting them as necessary when they exit.

![supervisor](assets/supervisor.svg)

In the depicted case the supervisor `A10` has child actors `A1`-`A6`. What it does if one of them – say `A4` - exits, is determined by its supervision strategy and by the child's restart variable and exit reason.

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

julia> foreach(a->exec(a, supervise, A10, threadid), A)

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

### Supervision strategy

| strategy | brief description |
|:---------|:------------------|
| `:one_for_one` | only the terminated actor is restarted (`A4`), |
| `:one_for_all` | all other child actors are terminated, then all child actors are restarted (`A1`-`A6`), |
| `:rest_for_one` | the children started after the terminated one are terminated, then all terminated ones are restarted (`A4`-`A6`). |

### Child restart options

| restart option | brief description |
|:---------------|:------------------|
| `:permanent` |  the child actor is always restarted, |
| `:temporary` | the child is never restarted, regardless of the supervision strategy, |
| `:transient` | the child is restarted only if it terminates abnormally, i.e., with an exit reason other than `:normal` or `:shutdown`. |

Supervisors allow for more automation and control of error handling in an actor system. For that they have the following API:

| API function | brief description |
|:-------------|:------------------|
| [`supervisor`](@ref) | start a supervisor actor, |
| [`supervise`](@ref) | add the current actor to a supervisor's child list, |
| [`unsupervise`](@ref) | delete the current actor from a supervisor's child list, |
| [`start_actor`](@ref) | tell a supervisor to start an actor as a child, |
| [`start_task`](@ref) | tell a supervisor to start a task as a child, |
| [`delete_child`](@ref) | tell a supervisor to remove an actor from its child list, |
| [`terminate_child`](@ref) | tell a supervisor to terminate a child and to remove it from its child list, |
| [`count_children`](@ref) | tell a supervisor to return a children count, |
| [`which_children`](@ref) | tell a supervisor to return a list of its children. |

With options we can limit how often a supervisor tries to restart children in a given timeframe. If it exceeds this limit, it terminates itself and all of its children with a warning.

## Checkpointing

A checkpointing actor can take user-defined checkpoints from current computations and restore them on demand. It can save checkpoints to a file and reload them. It can by other actors to save and to restore state.

| API function | brief description |
|:-------------|:------------------|
| [`checkpointing`](@ref) | start a checkpointing actor, |
| [`checkpoint`](@ref) | tell it to take a checkpoint, |
| [`restore`](@ref) | tell it to restore the last checkpoint, |
| [`get_checkpoints`](@ref) | tell it to return all checkpoints, |
| [`save_checkpoints`](@ref) | tell it to save the checkpoints, |
| [`load_checkpoints`](@ref) | tell it to load them from a file. |


## The `_ROOT` Actor

If `connect` or `monitor` are called from the REPL or a user script and not from an actor, the given link will be connected to or monitored by the `Actors._ROOT` actor.

## Fault Tolerance

To use the above mechanisms for fault-tolerance successfully, supervisors, monitors or `:sticky` actors must have behaviors which are unlikely to fail.
Therefore actors with complicated and error-prone behaviors should not be made monitors or `:sticky`.

Connections, monitors and supervisors represent quite different protocols. When do you use which?

1. If you want a failure in one actor to terminate others, then use [`connect`](@ref).
2. If instead you need to know or take action when some other actor or task exits for any reason, choose a monitor.
3. If you want to realize a hierarchy of actors and tasks, use supervisors.

The approaches can be combined to realize arbitrary structures of connected and monitored actors.

### Supervisory trees

Often you may be interested in building a hierarchical structure containing all actors and tasks in your application. This is called a supervisory tree, and there is the [`Supervisors`](https://github.com/JuliaActors/Supervisors.jl) package facilitating to build that.

[^1]: The definitive source for an outline of actor-based error handling is Joe Armstrong's dissertation: [Making reliable distributed systems in the presence of software errors](https://erlang.org/download/armstrong_thesis_2003.pdf)
[^2]: For implementation see also Joe Armstrong 2013. Programming Erlang, 2nd ed: Software for a Concurrent World; Manning, chs. 13 and 23 as well as the [Erlang/OTP](https://www.erlang.org/docs) and [Elixir](https://elixir-lang.org/docs.html) online documentations.
