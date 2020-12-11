# The `Actors` Protocol

```@meta
CurrentModule = Actors
```

`Actors` has predefined [message types](messages.md) with respective [`onmessage`](@ref) methods. This gives your actors predefined behaviors going beyond the classical [behavior](behaviors.md). API functions provide an interface to that messaging protocol and facilitate actor control and message exchange.

## Actor Control

Actors can be controlled with the following functions:

| API function | brief description |
|:-------------|:------------------|
| [`become!`](@ref) | cause an actor to switch its behavior |
| [`cast`](@ref) | cause an actor to execute its behavior function |
| [`exit!`](@ref) | cause an actor to terminate |
| [`init!`](@ref) | tell an actor to execute a function at startup |
| [`term!`](@ref) | tell an actor to execute a function when it terminates |
| [`update!`](@ref) | update an actor's internal state |

Actors can also operate on themselves, or rather they send themselves messages:

| API function | brief description |
|:-------------|:------------------|
| [`become`](@ref) | an actor switches its own behavior |
| [`self`](@ref) | an actor gets a link to itself |
| [`stop`](@ref) | an actor stops |

## Bidirectional Messages

To receive a reply from an actor there are two possibilities:

| API function | brief description |
|:-------------|:------------------|
| [`receive`](@ref) | after a [`send`](@ref) receive the [`Response`](@ref) asynchronously |
| [`request`](@ref) | `send` (implicitly) a message to an actor, **block** and `receive` the result synchronously |

The following functions do that for specific duties:

| API function | brief description |
|:-------------|:------------------|
| [`call`](@ref) | tell an actor to execute its behavior function and to send the result |
| [`exec`](@ref) | tell an actor to execute a function and to send the result |
| [`query`](@ref) | tell an actor's to send one of its internal state variables |

Those functions support both asynchronous and synchronous communication..

The following example shows the use of the API functions to control an actor in a REPL session:

```@repl actors
using Actors, .Threads
import Actors: spawn
act4 = spawn(Bhv(+, 4))       # start an actor adding to 4
exec(act4, Bhv(threadid))     # ask it its threadid
cast(act4, 4)                 # cast it 4
query(act4, :res)             # query the result
become!(act4, *, 4);          # switch the behavior to *
call(act4, 4)                 # call it with 4
exec(act4, Bhv(broadcast, cos, pi .* (-2:2))) # tell it to exec any function
Actors.diag(act4)             # check it
exit!(act4)                   # stop it
act4.chn.state
Actors.diag(act4)             # try to check it again
```

## Enhancing the Protocol

Actor protocols can be enhanced or altered by

- introducing new messages and `onmessage` methods,
- switching the actor mode and writing new `onmessage` methods for existing messages
- or both.

Libraries can do this for specific duties and plugin their protocols into `Actors`. Examples of such libraries are [`GenServers`](https://github.com/JuliaActors/GenServers.jl) and [`Guards`](https://github.com/JuliaActors/Guards.jl).
