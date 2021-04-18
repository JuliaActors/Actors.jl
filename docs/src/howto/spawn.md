# How to `spawn` actors
```@meta
CurrentModule = Actors
```

You create an actor by spawning it with a [behavior](../manual/behaviors.md). A behavior is

1. a callable Julia object and (if it accepts arguments)
2. the actors *acquaintance* parameters.

You must either import [`spawn`](@ref) explicitly or call it as `Actors.spawn`:

```@repl spawn
using Actors
import Actors: spawn
myactor = spawn(println, "Hello ")
```

We spawned the actor with a `println` behavior function and `"Hello "` as an acquaintance parameter on an available thread. The returned [`Link`](@ref) can be used to [`send`](@ref) a message (a *communication* parameter) to the actor:

```@repl spawn
send(myactor, "World!");
```

Our actor then executed `println("Hello ", "World!")`. It continues to wait for messages.

## with a user-defined behavior

We can write our own behavior function. Thereby we must consider, which arguments the actor should work with. As we have seen, an actor can have *acquaintance* parameters and it gets its *communication* parameters with an incoming communication. The behavior function must accept both those as arguments. In the following example we let that open and write a behavior function `thrd_println` which can be invoked with arbitrary `args...`:

```@repl spawn
using .Threads
function thrd_println(args...)
    println(args..., " from thread ", threadid())
end
```

In order to try that out, we want to start our actor on a given thread.

## on a thread

We can start an actor on a specific thread by using the `thrd` keyword argument:

```@repl spawn
nthreads()
myactor = spawn(thrd_println, "Hello ", "my ", thrd=2)
```

As before we can send the communication parameter to the actor and it will now call our user-defined behavior with it:

```julia
send(myactor, "world");

Hello my world from thread 2
```

Note that this works only if we have started Julia with the [`-t` or `--threads` flag](https://docs.julialang.org/en/v1.6/manual/command-line-options/) or the [`JULIA_NUM_THREADS`](https://docs.julialang.org/en/v1.6/manual/environment-variables/#JULIA_NUM_THREADS) environment variable set.

## on a distributed worker

If we have distributed worker processes available either by starting Julia with the `-p` or `--procs` flag or by starting them explicitly with `addprocs`, we can create actors on those by using the `pid` keyword argument to `spawn`:

```julia
julia> using Distributed

julia> worker = addprocs(2);      # start worker processes

julia> @everywhere using Actors   # make Actors available everywhere

julia> myactor = spawn(println, "Hello ", pid=worker[2])
Link{RemoteChannel{Channel{Any}}}(RemoteChannel{Channel{Any}}(3, 1, 351), 3, :default)
```

Now `spawn` returned a `Link` with a `RemoteChannel` to the actor and we can `send` it communication parameters as usual:

```julia
julia> send(myactor, "World!");

       From worker 3:    Hello World!
```

Actors are location-transparent and actors residing on different threads, processes and machines can communicate with each other by using their links.
