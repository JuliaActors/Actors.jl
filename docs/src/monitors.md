# Monitors

```@meta
CurrentModule = Actors
```

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
