# Supervisors

```@meta
CurrentModule = Actors
```

Our system now looks similar to the following:

![supervisor](../assets/supervisor.svg)

## Actor State Across Restarts

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

After restarting an actor, a supervisor updates its link to point to the newly created actor. But other copies of a link won't get updated and may then be out of sync.

If remote actors on other workers communicate with an actor over `RemoteChannel`s, they have copies of its link on their workers. After actor restart those are out of sync, and a remote actor may try to communicate with an old failed actor. To avoid this situation, you should [register](../howto/register.md) those actors and use their registered names to supervise them and communicate with them. The supervisor then will update the registered link.

## Task Supervision

## Supervisory trees

For larger applications you may be interested in building a hierarchical structure containing all actors and tasks. This is called a supervisory tree, and there is the [`Supervisors`](https://github.com/JuliaActors/Supervisors.jl) package facilitating to build that.
