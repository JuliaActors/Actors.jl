# How to deal with failures

```@meta
CurrentModule = Actors
```

`Actors` adopts Erlang's error handling philosophy [^1] and gives you a lot of options to deal with failures and to write fault-tolerant applications.

## Let it crash

In short if an actor fails, don't try to avoid it but

- let it crash and
- let some other actor do the error recovery.

Therefore as a basic mechanism you want actors to connect with peer, monitor or supervisor actors to signal failures in an actor system and to do something about it.

## [`connect` actors](@id connect)

If an actor fails, we want other actors that depend on it also actively fail before they get into some undefined state. To achieve that, we can connect dependent actors. Connected actors will propagate a failure to each other until they encounter a `:sticky` actor. To connect actors, you

1. have arbitrary actors (e.g. `A[1]` - `A[10]`),
2. tell some of them to [`connect`](@ref) with each other,
3. if needed, make some of them `:sticky` with [`trapExit`](@ref) in order to block the failure propagation.

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
```

If one of the connected actors fails, it will send an [`Exit`](@ref) message to its connected actors. Those will propagate the `Exit` further to their connected actors and terminate. If you made one `:sticky`, that will give a warning (and not exit).

```julia
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

With [`Actors.diag`](@ref) you can get an error log and access to the failed task from the `:sticky` actor `A[3]`.

You can view a graphical representation and further explanation [in the manual](../manual/connections.md).

## [`monitor` actors and tasks](@id monitor)

We can make an arbitrary actor a [monitor](../manual/monitors.md) that watches other actors and give warnings or execute specified options if they exit.

For example we start three actors A1-A3. We make `A3` a [`monitor`](@ref) for `A1` and `A2`. Then it gets a `Down` signal from its monitored actors if they exit.

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

## `supervise` actors

By supervision you can restart actors automatically if they fail or if the remote node fails, on which they reside.

Please see the

- [Supervise Actors tutorial](../tutorial/supervise.md) for an introduction,
- [Supervisors manual](../manual/supervisors.md) for illustration and explanations,
- [Node Failures manual](../manual/node_failures.md) for explanation of supervision of node failures,
- [Supervisors API reference](../api/supervision.md) for more informations.

## take checkpoints

## define exit and init behaviors

[^1]: See Joe Armstrong's dissertation: [Making reliable distributed systems in the presence of software errors](https://erlang.org/download/armstrong_thesis_2003.pdf), ch. 4.3, pp. 104 ...
