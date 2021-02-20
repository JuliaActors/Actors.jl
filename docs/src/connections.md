# Connections

```@meta
CurrentModule = Actors
```

If you [`connect`](@ref) actors, they send each other [`Exit`](@ref) messages when they fail, [`stop`](@ref) or [`exit!`](@ref). An actor propagates an `Exit` message to all its connected actors and then terminates

- if the exit `reason` is other than `:normal`,
- and if the actor is not `:sticky`.

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
