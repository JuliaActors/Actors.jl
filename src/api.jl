#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#

"""
```
become!(lk::Link, func, args1...; kwargs...)
become!(name::Symbol, ....)
```
Cause an actor to change behavior.

# Arguments
- actor `lk::Link` (or `name::Symbol` if registered),
- `func`: a callable object,
- `args1...`: (partial) arguments to `func`,
- `kwargs...`: keyword arguments to `func`.
"""
function become!(lk::Link, func, args...; kwargs...)
    isempty(args) && isempty(kwargs) ?
        send(lk, Become(func)) : 
        send(lk, Become(Bhv(func, args...; kwargs...)))
end
become!(name::Symbol, args...; kwargs...) = become!(whereis(name), args...; kwargs...)

"""
```
call(lk::Link, [from::Link,] args2...; timeout::Real=5.0)
call(name::Symbol, ....)
```
Call an actor to execute its behavior and to send a 
[`Response`](@ref) with the result. 

# Arguments
- actor `lk::Link` (or `name::Symbol` if registered), 
- `from::Link`: sender link, 
- `args2...`: remaining arguments to the actor.
- `timeout::Real=5.0`: timeout in seconds.

**Note:** If `from` is omitted, `call` blocks and returns the result
"""
call(lk::Link, from::Link, args...) = send(lk, Call(args, from))
call(lk::Link, args...; timeout::Real=5.0) = request(lk, Call, args...; timeout)
call(name::Symbol, args...; kwargs...) = call(whereis(name), args...; kwargs...)

"""
```
cast(lk::Link, args2...)
cast(name::Symbol, args2...)
```
Cast `args2...` to the actor `lk` (or `name` if registered) 
to execute its behavior with `args2...` without sending a 
response. 

**Note:** you can prompt the returned value with [`query`](@ref).
"""
cast(lk::Link, args...) = send(lk, Cast(args))
cast(name::Symbol, args...) = cast(whereis(name), args...)

"""
```
exec(lk::Link, from::Link, f, args...; kwargs...)
exec(lk::Link, f, args...; timeout::Real=5.0, kwargs...)
exec(name::Symbol, ....)
```

Ask an actor `lk` (or `name` if registered) to execute an 
arbitrary function and to send the returned value as 
[`Response`](@ref).

# Arguments
- actor `lk::Link` or `name::Symbol` if registered,
- `from::Link`: the link a `Response` should be sent to.
- `f`: a callable object,
- `args...; kwargs...`: arguments and keyword arguments to it,
- `timeout::Real=5.0`: timeout in seconds. Set `timeout=Inf` 
    if you don't want to timeout.

**Note:** If `from` is ommitted, `exec` blocks, waits and 
returns the result (with a `timeout`).
"""
function exec(lk::Link, from::Link, f, args...; kwargs...) 
    isempty(args) && isempty(kwargs) ?
        send(lk, Exec(f, from)) :
        send(lk, Exec(Bhv(f, args...; kwargs...), from))
end
function exec(lk::Link, f, args...; timeout::Real=5.0, kwargs...)
    isempty(args) && isempty(kwargs) ?
        request(lk, Exec, f; timeout=timeout) :
        request(lk, Exec, Bhv(f, args...; kwargs...); timeout)
end
exec(name::Symbol, args...; kwargs...) = exec(whereis(name), args...; kwargs...)

"""
```
exit!(lk::Link, reason=:normal)
exit!(name::Symbol, ....)
```
Tell an actor `lk` (or `name` if registered) to stop. If it 
has a [`term`](@ref _ACT) function, it calls that with 
`reason` as last argument. 
"""
exit!(lk::Link, reason=:normal) = send(lk, Exit(reason, fill(nothing, 3)...))
exit!(name::Symbol, reason=:normal) = exit!(whereis(name), reason)

"""
```
init!(lk::Link, f, args...; kwargs...)
init!(name::Symbol, ....)
```
Tell an actor `lk` to save the callable object `f` with the given 
arguments as an `init` object in its [`_ACT`](@ref) variable. 
The `init` object will be called by a supervisor at actor restart.

# Arguments
- actor `lk::Link` or `name::Symbol` if registered, 
- `f`: callable object,
- `args...`: arguments to `f`,
- `kwargs...`: keyword arguments to `f`.
"""
init!(lk::Link, f, args...; kwargs...) =
    send(lk, Init(Bhv(f, args...; kwargs...)))
init!(name::Symbol, args...; kwargs...) = init!(whereis(name), args...; kwargs...)

"""
```
query(lk::Link, [from::Link,] s::Symbol; timeout::Real=5.0)
query(name::Symbol, ....)
```

Query an actor about an internal state variable `s`. 

# Parameters
- actor `lk::Link` or `name::Symbol` if registered,
- `from::Link`: sender link,
- `s::Symbol` one of `:mode`,`:bhv`,`:res`,`:sta`,`:usr`.
- `timeout::Real=5.0`: 

**Note:** If `from` is omitted, `query` blocks and returns 
the response. In that case there is a `timeout`.

# Examples

```julia
julia> f(x, y; u=0, v=0) = x+y+u+v  # implement a behavior
f (generic function with 1 method)

julia> fact = spawn(Bhv(f, 1))     # start an actor with it
Link{Channel{Any}}(Channel{Any}(sz_max:32,sz_curr:0), 1, :default)

julia> query(fact, :mode)           # query the mode
:default

julia> cast(fact, 1)                # cast a 2nd argument to it
Actors.Cast((1,))

julia> query(fact, :res)            # query the result
2

julia> query(fact, :sta)            # query the state

julia> query(fact, :bhv)            # query the behavior
Bhv(f, (1,), Base.Iterators.Pairs{Union{},Union{},Tuple{},NamedTuple{(),Tuple{}}}(), Actors.var"#2#4"{Base.Iterators.Pairs{Union{},Union{},Tuple{},NamedTuple{(),Tuple{}}},typeof(f),Tuple{Int64}}(Base.Iterators.Pairs{Union{},Union{},Tuple{},NamedTuple{(),Tuple{}}}(), f, (1,)))
```
"""
query(lk::Link, from::Link, s::Symbol=:sta) = send(lk, Query(s, from))
query(lk::Link, s::Symbol=:sta; timeout::Real=5.0) = request(lk, Query, s; timeout)
query(name::Symbol, args...; kwargs...) = query(whereis(name), args...; kwargs...)
    
"""
```
term!(lk::Link, f, args1...; kwargs...)
term!(name::Symbol, ....)
```
Tell an actor `lk` (or `name::Symbol` if registered) to 
execute `f` with the given partial arguments and an
exit reason when it terminates. 

The exit reason is added by the actor to `args1...` when it 
exits.
"""
term!(lk::Link, f, args...; kwargs...) = 
    send(lk, Term(Bhv(f, args...; kwargs...)))
term!(name::Symbol, args...; kwargs...) = term!(whereis(name), args...; kwargs...)

"""
    trapExit(lk::Link=self(), mode=:sticky)

Change the mode of an actor.

A `:sticky` actor does not exit if it receives an [`Exit`](@ref) 
signal from a connected actor and does not propagate it further. 
Instead it reports the failure and saves a link to the failed actor. 

See [`diag`](@ref) for getting links to failed actors 
from a `:sticky` actor.
"""
trapExit(lk::Link=self(), mode=:sticky) = send(lk, Update(:mode, mode))

"""
```
update!(lk::Link, x; s::Symbol=:sta)
update!(lk::Link, arg::Args)
update!(name::Symbol, ....)
```
Update an actor's internal state `s` with `args...`.

# Arguments
- actor `lk::Link` or `name::Symbol` if registered,
- `x`: value/variable to update the choosen state with,
- `arg::Args`: arguments to update,
- `s::Symbol`: one of `:arg`, `:mode`, `:name`, `:self`, `:sta`, `:usr`.

*Note:* If you want to update the stored arguments to the 
behavior function with `s=:arg`, you must pass an [`Args`](@ref) 
to `arg`. If `Args` has keyword arguments, they are merged 
with existing keyword arguments to the behavior function.

# Example
```julia
julia> update!(fact, 5)       # update the state variable
Actors.Update(:sta, 5)

julia> query(fact, :sta)      # query it
5

julia> update!(fact, Args(0, u=5, v=5));  # update arguments to the behavior 

julia> call(fact, 0)          # call the actor with 0
10
```
"""
update!(lk::Link, x; s::Symbol=:sta) = send(lk, Update(s, x))
update!(lk::Link, arg::Args) = send(lk, Update(:arg, arg))
update!(name::Symbol, args...; kwargs...) = update!(whereis(name), args...; kwargs...)
