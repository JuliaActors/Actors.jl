# How to get information

```@meta
CurrentModule = Actors
```

Actors are implemented as Julia `Task`s running asynchronously and are represented by a messaging [`Link`](@ref) to them or by a [registered name](../api/registry.md).

## about an actor

You can use an actor's link (or its registered name) to get information about it:

```julia
julia> using Actors

julia> import Actors: spawn

julia> myBehavior(lk, f, args...) = send(lk, f(args...))
myBehavior (generic function with 1 method)

julia> me = newLink()
Link{Channel{Any}}(Channel{Any}(32), 1, :local)

julia> myactor = spawn(myBehavior, me)
Link{Channel{Any}}(Channel{Any}(32), 1, :default)

julia> info(myactor)
Actor    default
Behavior myBehavior
Pid      1, Thread 1
Task     @0x000000010d944230
Ident    x-d-ukih-hamub
```

[`info`](@ref) gives you some information about your actor. The system will on each worker `pid` identify an actor as a Julia `Task`. In order make it better identifiable for a human, the task address is also given as a [Proquint](https://github.com/pbayer/Proquint.jl) identifier:

```julia
julia> using Proquint

julia> quint2uint("x-d-ukih-hamub")
0x000000010d944230

julia> info(myactor).task
0x000000010d944230
```

If you [`register`](@ref) an actor, you can use its registered name to get the information. Then `info` will show also the actor's name:

```julia
julia> register(:myname, myactor)
true

julia> info(:myname)
Actor    default
Behavior myBehavior
Pid      1, Thread 1
Task     @0x000000010d944230
Ident    x-d-ukih-hamub
Name     myname
```

## about the actor's task

There are two ways to get the `Task` variable from an actor:

1. you [`spawn`](@ref) it with a `taskref` keyword argument or
2. you use [`Actors.diag`](@ref).

```julia
julia> t = Ref(Actors.diag(myactor, :task))
Base.RefValue{Task}(Task (runnable) @0x000000010d944230)

julia> t[]
Task (runnable) @0x000000010d944230
```

Note: if an actor is on a worker process (`pid` > 1), you cannot get access to its `Task`. Instead you will get a string representation of it.

## about a failed actor

If an actor fails, info will return the failed `Task`, which shows a clickable stack-trace in the REPL:

```julia
julia> send(myactor, :boom)
(:boom,)

julia> info(myactor)
Task (failed) @0x000000010d944230
MethodError: objects of type Symbol are not callable
Stacktrace:
 [1] myBehavior(::Link{Channel{Any}}, ::Symbol)
....

julia> typeof(ans)
Task
```

We can get the same information from the `Ref{Task}`-variable, we created earlier:

```julia
julia> t
Base.RefValue{Task}(Task (failed) @0x000000010d944230)

julia> t[]
Task (failed) @0x000000010d944230
MethodError: objects of type Symbol are not callable
Stacktrace:
 [1] myBehavior(::Link{Channel{Any}}, ::Symbol)
....
```

## about actor state

For diagnostic purposes it is possible to get access to an actor's state by using [`Actors.diag`](@ref). See also [Diagnostics](../reference/diag.md).
