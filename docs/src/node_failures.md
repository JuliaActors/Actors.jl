# Node Failures

```@meta
CurrentModule = Actors
```

In distributed computing node failures can occur. The occurrence of a single node failure is not very likely but node failures can be a problem for long running applications executed on many nodes.

## Remote failure detection

If an actor with a remote link is put under supervision (under a supervisor running on another worker), the supervisor starts a special child actor (RNFD: remote note failure detection) checking remote links periodically for node failures.

If it detects a `ProcessExitedException` on a supervised `RemoteChannel`, it sends a `NodeFailure` signal to the supervisor. The supervisor then handles it as if an actor failure had occurred.

## Actor restart on spare nodes

Generally a supervisor restarts a failed remote (`:transient` or `:permanent`) child actor on the same `pid` (process id) where it ran before failure. But in case of a worker failure the actors that ran on it are restarted on a spare process. The supervisor determines the spare processes as follows:

1. A [`supervisor`](@ref) can be started with a `spares` option like `spares = [5,6,7]`, with given spare `pid`s. For actor restarts after node failures the supervisor chooses first those processes and removes them from the `spares` list.
2. If there are no spare nodes (left), the supervisor restarts actors on the highest free `pid` available (not used by some of its child actors).
3. If there is no free `pid`, the supervisor restarts on a randomly chosen available worker.

## Example

We setup six actors `A1..A6` distributed over `pid`s 2..4 and put them under supervision of `A10` on `pid` 1 with two spare worker `pid`s 5,6. `A10` starts a `RFND` actor checking the supervised `RemoteChannel`s each second for node failures.

```julia
```

Our system now looks similar to the following:

![supervisor rfd 1](assets/supervisor_rfd1.svg)

If the worker process with pid 3 fails, the supervisor restarts  actors A3 and A4 on the first spare worker process (`pid` 5). 

```julia
```

(With supervision strategy `:one_for_all` or `:rest_for_one` the supervisor would have shutdown other child actors as well (`A1,A2,A5,A6` or `A5,A6` respectively) and restarted them on their same `pid`s.) The system after actor restart looks as follows:

![supervisor rfd 2](assets/supervisor_rfd2.svg)

`pid` 3 is gone and the supervisor has one spare worker, `pid` 6 left.
