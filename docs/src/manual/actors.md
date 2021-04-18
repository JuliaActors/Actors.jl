# Actors and Julia

```@meta
CurrentModule = Actors
```

In one of his later papers (2010) Carl Hewitt wrote:

> It is important to distinguish the following:
>
> - modeling arbitrary computational systems using Actors. It is difficult to find physical computational systems (regardless of how idiosyncratic) that cannot be modeled using Actors.
> - securely implementing practical computational applications using Actors remains an active area of research and development. [^1]

We focus on the second point, namely on practical computational applications.

## Julia is Well Suited for Actors

`Actors` uses Julia's `Task`s to execute functions concurrently and `Channel`s to let them communicate. An actor has a Julia function or callable object as [behavior](behaviors.md). That gets parametrized with the arguments given to the actor at startup (acquaintances). The other arguments are delivered via messages (communication). Then an actor executes its behavior. Actors incorporate processing, storage and communication. Functions thus become responsive and composable in new ways.

## Actors Complement Julia

Actors give Julia users additional ways to deal with concurrency. Sutter and Larus justified that as follows:

> We need higher-level language abstractions, including evolutionary extensions to current imperative languages, so that existing applications can incrementally become concurrent. The programming model must make concurrency easy to understand and reason about, not only during initial development but also during maintenance. [^2]

Actors support clear, correct concurrent programs and are an alternative to sharing memory in concurrent computing:

- Share by communicating [^3] to functions and
- use functions to localize variables and
- make actors serve mutable variables without using locks.

You can use actors in common multi-threading or distributed Julia code.

## Multi-threading

Julia's manual encourages the use of locks [^4] in order to ensure data-race freedom. But be aware that

> they are not composable. You can’t take two correct lock-based pieces of code, combine them, and know that the result is still correct. Modern software development relies on the ability to compose libraries into larger programs, and so it is a serious difficulty that we cannot build on lock-based components without examining their implementations. [^5]

An actor controlling the access to a variable or to another resource is lock-free and there are no limits to composability. Therefore if you write multi-threaded programs which should be composable or maybe used by other programs within a lock, you might consider using `Actors`.

## Distributed Computing

Actors are location transparent. You can share their links across workers to access the same actor on different workers. If local links are sent to a remote actor, they are automatically converted to remote links.

## Fault Tolerance

`Actors` provides explicit methods for fault tolerant computing used mainly in telecommunications and internet services with Erlang/OTP [^6]:

- *group* actors and force them to fail together,
- *monitor* tasks and actors and take action if they fail or time out,
- *supervise* tasks and actors and restart them if a failure occurs.

Based on that *checkpoint* and *restore* as used for  fault-tolerance in high performance computing (HPC) can be implemented.

!!! note "This is currently work in progress!"
    Those features should be considered experimental!

## Actor Isolation

In order to avoid race conditions actors have to be strongly isolated from each other:

1. they do not share state,
2. they must not share mutable variables.

An actor stores the behavior function and arguments to it, results of computations and more. Thus it has state and this influences how it behaves.

But it does **not share** its state variables with its environment (only for diagnostic purposes). The [user API functions](../api/user_api.md) functions are a safe way to access actor state via messaging.

Mutable variables in Julia can be sent over local channels without being copied. Accessing those variables from multiple threads can cause race conditions. The programmer has to be careful to avoid those situations either by

- not sharing them between actors,
- copying them when sending them to actors or
- representing them by an actor.

When sending mutable variables over remote links, they are automatically copied.

## Actor Local Dictionary

Since actors are Julia tasks, they have a local dictionary in which you can store values. You can use [`task_local_storage`](https://docs.julialang.org/en/v1/base/parallel/#Base.task_local_storage-Tuple{Any}) to access it in behavior functions. But normally argument passing should be enough to handle values in actors.

[^1]: Carl Hewitt. Actor Model of Computation: Scalable Robust Information Systems.- [arXiv:1008.1459](https://arxiv.org/abs/1008.1459)
[^2]: H. Sutter and J. Larus. Software and the concurrency revolution. ACM Queue, 3(7), 2005.
[^3]: "Do not communicate by sharing memory; instead, share memory by communicating." see Effective Go: [Share by Communicating](https://golang.org/doc/effective_go.html#sharing)
[^4]: see [Data race freedom](https://docs.julialang.org/en/v1/manual/multi-threading/#Data-race-freedom) in the Julia manual.
[^5]: H. Sutter and J. Larus. see above
[^6]: see Joe Armstrong, 2003: [Making reliable distributed systems in the presence of software errors](https://erlang.org/download/armstrong_thesis_2003.pdf)
