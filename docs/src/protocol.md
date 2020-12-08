# Actor Protocols

```@meta
CurrentModule = Actors
```

`Actors` introduces predefined [messages](messages.md) with [`onmessage`](@ref) methods for them. This is a protocol with predefined behaviors for your actors. It allows you to control and to do all sorts of things with them.

## Actor Control

Actors can be controlled with the following functions:

- [`become!`](@ref): cause an actor to switch its behavior,
- [`cast`](@ref): cause an actor to execute its behavior function,
- [`exit!`](@ref): cause an actor to terminate,
- [`init!`](@ref): tell an actor to execute a function at startup,
- [`term!`](@ref): tell an actor to execute a function when it terminates,
- [`update!`](@ref): update an actor's internal state.

Those functions are wrappers to the message [protocol](protocol.md) and to [`send`](@ref).

Actors can also operate on themselves, or rather they send messages to themselves:

- [`become`](@ref): an actor switches its own behavior,
- [`self`](@ref): an actor gets a link to itself,
- [`stop`](@ref): an actor stops.

## Bidirectional Messages

What if you want to receive a reply from an actor? Then there are two possibilities:

1. [`send`](@ref) a message to an actor and then [`receive`](@ref) the [`Response`](@ref) asynchronously,
2. [`request`](@ref): send a message to an actor, **block** and receive the result synchronously.

The following functions do this for specific duties:

- [`call`](@ref) an actor to execute its behavior function and to send the result,
- [`exec`](@ref): tell an actor to execute a function and to send the result,
- [`query`](@ref) tell an actor's to send one of its internal state variables.

If you provide those functions with a return link, they will use [`send`](@ref) and you can then [`receive`](@ref) the [`Response`](@ref) from the return link later. If you 
don't provide a return link, they will use [`request`](@ref) to block and return the result. Note that you should not use blocking when you need to be strictly responsive.

## Using the API

The [API](api.md) functions allow to work with actors without using messages explicitly:

```@repl actors
using Actors, .Threads
import Actors: spawn
act4 = spawn(Bhv(+, 4))       # start an actor adding to 4
exec(act4, Bhv(threadid))    # ask it its threadid
cast(act4, 4)                 # cast it 4
query(act4, :res)              # query the result
become!(act4, *, 4);           # switch the behavior to *
call(act4, 4)                 # call it with 4
exec(act4, Bhv(broadcast, cos, pi .* (-2:2))) # tell it to exec any function
Actors.diag(act4)              # check it
exit!(act4)                    # stop it
act4.chn.state
Actors.diag(act4)              # try to check it again
```

## Enhancing the Protocol

Actor protocols can be enhanced or altered by

- introducing new messages and onmessage methods,
- switching the actor mode and writing new onmessage methods for existing messages
- or both.


