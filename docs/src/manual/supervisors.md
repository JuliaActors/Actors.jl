# Supervisors

```@meta
CurrentModule = Actors
```

If we want actors to be restarted automatically if they fail, we can use [`supervise`](@ref) to put them under the supervision of a [`supervisor`](@ref) actor. Lets consider a system of six actors `A1` - `A6` under supervision of the supervisor `A10`. Such a system may look as follows:

![supervisor](../assets/supervisor.svg)

The six actors `A1` - `A6` are connected to their supervisor A10 and will send it an [`Exit`](@ref) message before they exit. They will not notify each other. It is the duty of the supervisor to decide, what to do.

What the supervisor does, should one of its child actors – say `A4` - fail, depends on three parameters:

1. the [supervision strategy](@ref strategies) (`:one_for_one`, `:one_for_all` and `:rest_for_one`) of the `supervisor`,
2. the [restart option](@ref restart) (`:transient`, `:permanent`, `:temporary`) of the `supervise`d child and
3. the `Exit` reason.

## Supervision strategy

Let's discuss the depicted case of actor `A4` failing: We assume `:transient` child actors, meaning they are restarted if they terminate abnormally, that is, if they fail. Now what happens depends solely on the supervisor's strategy.

| strategy | the supervisor will restart ...|
|:---------|:----------------------------|
| `:one_for_one` | the failed actor `A4`, |
| `:one_for_all` | all child actors `A1` - `A6`, |
| `:rest_for_one` | the failed actor `A4` and the actors `A5` and `A6` registered to the supervisor after it. |

In the second and third case the other actors are shutdown by the supervisor before being restarted.

You can see this in action in the [Supervise Actors tutorial](../tutorial/supervise.md).

## Actor State Across Restarts

A failing actor transfers its behavior (behavior function and acquaintance variables) to the supervisor before it exits. Thus the supervisor can restart that actor with its state, that it had before processing the last message. That is also demonstrated in the [Supervise Actors tutorial](../tutorial/supervise.md).

That strategy maybe sufficient for many cases, but you can change it by setting termination and restart callbacks.

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

## Preserving Actor Links

After restarting an actor, a supervisor updates its link to point to the newly created actor. But copies of a link won't get updated and may then be out of sync.

If remote actors on other workers communicate with an actor over `RemoteChannel`s, they have copies of its link on their workers. After actor restart those are out of sync, and a remote actor may then try to communicate with an old failed actor. To avoid this situation, you should [register](../howto/register.md) supervised remote actors and use their registered names to supervise them and communicate with them. The supervisor then will update the registered link.

## Limit Restarts

A supervisor takes two additional arguments: `max_restarts` and `max_seconds` where you can limit the number of restarts it does in the `max_seconds` time frame. If failures exceed that limit, a supervisor will shutdown its child actors and itself with an error message.

## Task Supervision

## Supervisory trees

For larger applications you may be interested in building a hierarchical structure containing all actors and tasks. This is called a supervisory tree, and there is the [`Supervisors`](https://github.com/JuliaActors/Supervisors.jl) package facilitating to build that.
