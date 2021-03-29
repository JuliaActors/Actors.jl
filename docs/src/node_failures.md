# Node Failures

```@meta
CurrentModule = Actors
```

In distributed computing node failures can occur. The occurrence of a single node failure is not very likely but node failures can be a problem for long running applications executed on many nodes.

## Remote failure detection

If an actor with a remote link is put under supervision (under a supervisor running on another worker), the supervisor starts a special child actor (RNFD: remote note failure detection) checking remote links periodically for node failures. 

If it detects a `ProcessExitedException` on a supervised `RemoteChannel`, it sends a `NodeFailure` signal to the supervisor. The supervisor then handles it as if an actor failure had occurred.

## Actor restart on spare nodes

In case of a failure of a worker, the actors that ran on it are restarted on a spare worker.
