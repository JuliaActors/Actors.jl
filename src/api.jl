#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#

"""
```
become!(lk::Link, bhv::Bhv)
become!(lk::Link, func, args1...; kwargs...)
become!(name::Symbol, ....)
```
Cause an actor to change behavior.

# Arguments
- actor `lk::Link` (or `name::Symbol` if registered),
- `bhv`: a [`Bhv`](@ref) or a functor implementing the new behavior,
- `func::Function`: a function,
- `args1...`: (partial) arguments to `func`,
- `kwargs...`: keyword arguments to `func`.
"""
become!(lk::Link, bhv) = send(lk, Become(bhv))
become!(lk::Link, func::F, args...; kwargs...) where F<:Function = become!(lk, Bhv(func, args...; kwargs...))
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
call(lk::Link, args...; timeout::Real=5.0) = request(lk, Call, args...; timeout=timeout)
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
exec(lk::Link, from::Link, func, args...; kwargs...)
exec(lk::Link, from::Link, f::Bhv)
exec(lk::Link, f::Bhv; timeout::Real=5.0)
exec(name::Symbol, ....)
```

Ask an actor `lk` (or `name` if registered) to execute an 
arbitrary function and to send the returned value as 
[`Response`](@ref).

# Arguments
- actor `lk::Link` or `name::Symbol` if registered,
- `from::Link`: the link a `Response` should be sent to.
- `func`: a callable object,
- `args...; kwargs...`: arguments and keyword arguments to it,
- `fu::Bhv`: a [`Bhv`](@ref) with a callable object and
    its arguments,
- `timeout::Real=5.0`: timeout in seconds. Set `timeout=Inf` 
    if you don't want to timeout.

**Note:** If `from` is ommitted, `exec` blocks, waits and 
returns the result (with a `timeout`).
"""
exec(lk::Link, from::Link, func, args...; kwargs...) =
    send(lk, Exec(Bhv(func, args...; kwargs...), from))
exec(lk::Link, from::Link, fu::Bhv) = send(lk, Exec(fu, from))
exec(lk::Link, f::Bhv; timeout::Real=5.0) =
    request(lk, Exec, f; timeout=timeout)
exec(name::Symbol, args...; kwargs...) = exec(whereis(name), args...; kwargs...)

"""
```
exit!(lk::Link, reason=:ok)
exit!(name::Symbol, ....)
```
Tell an actor `lk` (or `name` if registered) to exit. If it 
has a [`term`](@ref _ACT) function, it calls it with 
`reason` as last argument. 

!!! note "This behavior is not yet fully implemented!"

    It is needed for supervision.

"""
exit!(lk::Link, reason=:ok) = send(lk, Exit(reason))
exit!(name::Symbol, reason=:ok) = exit!(whereis(name), reason)

"""
```
init!(lk::Link, func, args...; kwargs...)
init!(name::Symbol, ....)
```
Tell an actor `lk` to save the `func` with the given 
arguments as an [`init`](@ref _ACT) function and to execute 
it.

The `init` function will be called at actor restart.

!!! note "This behavior is not yet implemented!"

    It is needed for supervision.
"""
init!(lk::Link, f::F, args...; kwargs...) where F<:Function = 
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
query(lk::Link, s::Symbol=:sta; timeout::Real=5.0) = request(lk, Query, s, timeout=timeout)
query(name::Symbol, args...; kwargs...) = query(whereis(name), args...; kwargs...)
    
"""
```
term!(lk::Link, func, args...; kwargs...)
term!(name::Symbol, ....)
```
Tell an actor `lk` (or `name::Symbol` if registered) to 
execute `func` with the given partial arguments and an
exit reason when it terminates. 

The exit reason is added by the actor to `args1...` when it 
exits.

!!! note "This behavior is not yet implemented!"

    It is needed for supervision.
"""
term!(lk::Link, func, args...; kwargs...) = 
    send(lk, Term(Bhv(func, args...; kwargs...)))
term!(name::Symbol, args...; kwargs...) = term!(whereis(name), args...; kwargs...)

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
- `s::Symbol`: one of `:arg`,`:mode`,`:name`,`:self`,`:sta`,`:usr`.

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
