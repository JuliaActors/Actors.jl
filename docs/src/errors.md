# Overview

```@meta
CurrentModule = Actors
```

## Errors

## Error-handling

`Actors` provides Erlang/OTP-like [^1][^2] mechanisms and message protocols to handle errors in actors and tasks.

The basic philosophy is not to defend against errors but to detect them and then to take action about them. There are several mechanisms for that: 

1. **connections**: actors connect to each other to trap errors,
2. **monitors**: actors and tasks can be monitored,
3. **supervisors**: actors can be supervised and restarted,
4. **checkpointing**: actors can take checkpoints and restore them.

Those mechanisms can be used to handle errors and to write fault-tolerant programs.

## The `_ROOT` Actor

If `connect` or `monitor` are called from the REPL or a user script and not from an actor, the given link will be connected to or monitored by the `Actors._ROOT` actor.

[^1]: An outline of actor-based error handling is Joe Armstrong's dissertation: [Making reliable distributed systems in the presence of software errors](https://erlang.org/download/armstrong_thesis_2003.pdf)
[^2]: For implementation see also Joe Armstrong 2013. Programming Erlang, 2nd ed: Software for a Concurrent World; Manning, chs. 13 and 23 as well as the [Erlang/OTP](https://www.erlang.org/docs) and [Elixir](https://elixir-lang.org/docs.html) online documentations.
