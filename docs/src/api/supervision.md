# Supervisors

```@meta
CurrentModule = Actors
```

Supervisors allow some automation and control of error handling in an actor system. A supervisor actor can restart its children if they should terminate.

## [Supervision Strategies](@id strategies)

What a [`supervisor`](@ref) does if one of its children terminates, is determined by its supervision `strategy` argument:

| strategy | brief description |
|:---------|:------------------|
| `:one_for_one` | only the terminated actor is restarted (`A4`), |
| `:one_for_all` | all other child actors are terminated, then all child actors are restarted (`A1`-`A6`), |
| `:rest_for_one` | the children started after the terminated one are terminated, then all terminated ones are restarted (`A4`-`A6`). |

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
| [`start_actor`](@ref) | tell a supervisor to start an actor as a child, |
| [`start_task`](@ref) | tell a supervisor to start a task as a child, |
| [`terminate_child`](@ref) | tell a supervisor to terminate a child and to remove it from its child list, |
| [`set_strategy`](@ref) | tell a supervisor to change its supervision strategy, |
| [`count_children`](@ref) | tell a supervisor to return a children count, |
| [`which_children`](@ref) | tell a supervisor to return a list of its children. |

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
