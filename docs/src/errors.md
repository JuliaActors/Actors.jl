# Overview

```@meta
CurrentModule = Actors
```

## Errors

Failures in computations are due to hardware, software, and human cause failures. A single cause for such errors is difficult to quantify and depends strongly on circumstances. Therefore we can conclude that 

- failures are in principle unavoidable and that
- we must take care of all three sources of errors [^1].

## Error-handling

An actor system consists of computationally separate and concurrent entities. If one actor fails, the system does not crash immediately as do sequentially organized applications. Other actors can continue their tasks as long as they do not try to communicate with the failed one. The system now is in a problematic state, and we must somehow prevent further cascading failures.

The solution is not to defend against errors but to organize the system such that actors

- monitor each other for failures and
- perform corrective actions if a failure is detected.

`Actors` provides the following mechanisms [^1][^2][^3] to handle errors in actors and tasks:

| mechanism | brief description |
|:----------|:------------------|
| **connections** | Actors connect and propagate an [`Exit`](@ref) to each other. |
| **monitors** | Actors can monitor other actors and tasks. |
| **supervisors** | Actors can be supervised and restarted. |
| **checkpointing** | Actors can save checkpoints to checkpointing actors and restore them. |

-----

## The `_ROOT` Actor

If `connect` or `monitor` are called from the REPL or a user script and not from an actor, the given link will be connected to or monitored by the `Actors._ROOT` actor.

[^1]: Egwutuoha, I.P., Levy, D., Selic, B. et al. A survey of fault tolerance mechanisms and checkpoint/restart implementations for high performance computing systems. J Supercomput 65, 1302–1326 (2013). https://doi.org/10.1007/s11227-013-0884-0
[^2]: An outline of actor-based error handling is Joe Armstrong's dissertation: [Making reliable distributed systems in the presence of software errors](https://erlang.org/download/armstrong_thesis_2003.pdf)
[^3]: For implementation see also Joe Armstrong 2013. Programming Erlang, 2nd ed: Software for a Concurrent World; Manning, chs. 13 and 23 as well as the [Erlang/OTP](https://www.erlang.org/docs) and [Elixir](https://elixir-lang.org/docs.html) online documentations.
