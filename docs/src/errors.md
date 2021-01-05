# Error Handling

`Actors` provides Erlang-like [^1] mechanisms to

1. handle errors in actors and tasks and to
2. write fault-tolerant programs.

## Let it Crash

- detecting errors,
- connecting actors,
- checking tasks,
- performing an action when an actor or a task dies

## Fault-Tolerance

> Fault tolerance is an important subject in distributed systems design. Fault tolerance is defined as the characteristic by which a system can mask the occurrence and recovery from failures. In other words, a system is fault tolerant if it can continue to operate in the presence of failures. [^2]

- system actors,
- restarting actors,
- dynamic code loading

## Supervision

- task supervision
- supervision tree

[^1]: The definitive source for actor-based error handling is Joe Armstrong's dissertation: [Making reliable distributed systems in the presence of software errors](https://erlang.org/download/armstrong_thesis_2003.pdf)
[^2]: Maarten van Steen, Andrew S. Tanenbaum. Distributed Systems, v3.02 (2018).- p. 499
