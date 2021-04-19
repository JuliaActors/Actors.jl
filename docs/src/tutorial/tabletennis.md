# [Simulate a Game](@id table-tennis)

Now a small toy example for concurrency with actors using only some classic actor primitives:

| Primitive             | Brief description            |
|:----------------------|:-----------------------------|
| `spawn(bhv)` | create an actor from a behavior and return a link, |
| `self()` | get the address of the current actor, |
| `send(addr, msg)` | send a message to an actor, |

We simulate table-tennis where a player has a name and a capability. If he gets a ball with a difficulty exceeding his capability, he looses it. Players log to a print server actor.

```julia
using Actors, Printf, Random
import Actors: spawn

struct Player{S,T}
    name::S
    capa::T
end

struct Ball{T,S,L}
    diff::T
    name::S
    from::L
end

struct Serve{L}
    to::L
end

function (p::Player)(prn, b::Ball)
    if p.capa ≥ b.diff
        send(b.from, Ball(rand(), p.name, self()))
        send(prn, p.name*" serves "*b.name)
    else
        send(prn, p.name*" looses ball from "*b.name)
    end
end
function (p::Player)(prn, s::Serve)
    send(s.to, Ball(rand(), p.name, self()))
    send(prn, p.name*" serves ")
end
```

In order to get reproducible results we initialize our random generator on each thread and assign threads to  players.

The print server `prn` gets an anonymous function as behavior. The two players `ping` and `pong` get the print server's link as acquaintance. We start the game by sending `ping` the `:serve` command and the address of `pong`:

```julia
@threads for i in 1:nthreads()
    Random.seed!(2021+threadid())
end

prn = spawn(s->print(@sprintf("%s\n", s))) 
ping = spawn(Player("Ping", 0.8), prn, thrd=3)
pong = spawn(Player("Pong", 0.75), prn, thrd=4)

send(ping, Serve(pong))
```

To execute the program we include the file:

```julia
julia> include("examples/pingpong.jl");

Ping serves 
Pong serves Ping
Ping serves Pong
Pong serves Ping
Ping serves Pong
Pong looses ball from Ping
```

Actors are great for simulation.
