# Behaviors

```@meta
CurrentModule = Actors
```

A behavior is a ...

> ... function to express what an actor does when it processes a message. [^1]

Behaviors can be set with [`spawn`](@ref) and changed with [`become!`](@ref). Inside a behavior function an actor can change its own behavior with [`become`](@ref). In both cases no arguments, partial or full arguments and keyword arguments can be specified with the behavior. 

## Partial Arguments

Partial arguments can fix the behavior function to work with given variables, e.g. a certain database, a state variable, a user request ... This is very useful.

## [Behavior Dispatch](@id dispatch)

If additional arguments arrive with a message, an actor composes the previously set partial arguments with the new arguments and dispatches the behavior function with them. The arguments are composed from left to right, first the partial arguments, then the received ones.

## Keyword Arguments

Keyword arguments are not dispatched on but they too can represent state and therefore can change the behavior.

[^1]: see the [Actor Model](https://en.wikipedia.org/wiki/Actor_model#Behaviors) on Wikipedia.
