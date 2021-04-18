# How to (not) share variables

**Problem:** When actors or tasks alike share objects concurrently they must avoid [data races](https://en.wikipedia.org/wiki/Race_condition#Data_race). Locks have serious [disadvantages](https://en.wikipedia.org/wiki/Lock_(computer_science)#Disadvantages). How can we make data sharing safe without using locks?

## share actors instead of variables

**Solution:** Don't share memory. Instead define an actor that serves the object to its clients. Start it and share the actor link and its interface. Thus you share memory by communicating.

## define a message API

## write a behavior

## share the actor link or name

## use actor infrastructure libraries

There are `Actors` infrastructure libraries which can ease your use of such servers:

- [Guards](https://github.com/JuliaActors/Guards.jl): Actors guarding access to mutable variables and
- [GenServers](https://github.com/JuliaActors/GenServers.jl): Abstracting out concurrency to generic servers.
