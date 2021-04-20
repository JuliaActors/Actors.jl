# Supervisors

```@meta
CurrentModule = Actors
```

Supervisors allow some automation and control of error handling in an actor system. A supervisor actor can restart its children if they should terminate.

## [Supervision Strategies](@id strategies)

What a [`supervisor`](@ref) does if one of its children terminates, is determined by its supervision `strategy` argument:

| strategy | brief description |
|:---------|:------------------|
| `:one_for_one` | only the terminated actor is restarted (default strategy), |
| `:one_for_all` | all other child actors are shutdown, then all child actors are restarted, |
| `:rest_for_one` | actors registered to the supervisor after the terminated one are shutdown, then the terminated one and the rest are restarted. |

## [Child Restart Options](@id restart)

Child `restart` options with [`supervise`](@ref) allow for yet finer child-specific control of restarting:

| restart option | brief description |
|:---------------|:------------------|
| `:permanent` |  the child actor is always restarted, |
| `:temporary` | the child is never restarted, regardless of the supervision strategy, |
| `:transient` | the child is restarted only if it terminates abnormally, i.e., with an exit reason other than `:normal` or `:shutdown`. |

## Supervision API

Supervisors have the following API:

| API function | brief description |
|:-------------|:------------------|
| [`supervisor`](@ref) | start a supervisor actor, |
| [`supervise`](@ref) | add an actor to a supervisor's child list, |
| [`unsupervise`](@ref) | delete an actor or task from a supervisor's child list, |
| [`start_actor`](@ref) | start an actor as a child, |
| [`start_task`](@ref) | start a task as a child, |
| [`terminate_child`](@ref) | terminate a child and to remove it from its child list, |
| [`set_strategy`](@ref) | change the supervision strategy, |
| [`count_children`](@ref) | return a children count, |
| [`which_children`](@ref) | return a list of all children. |

## Functions

```@docs
supervisor
supervise
unsupervise
set_strategy
start_actor
start_task
count_children
which_children
terminate_child
```
