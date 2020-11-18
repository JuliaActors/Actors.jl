#
# This file is part of the YAActL.jl Julia package, MIT license
#
# Paul Bayer, 2020
#

"""
    Args(args...; kwargs...)

A structure for updating arguments to an actor's behavior.
"""
struct Args{A,B}
    args::A
    kwargs::B

    Args(args...; kwargs...) = new{typeof(args),typeof(kwargs)}(args, kwargs)
end

"""
```
become!(lk::Link, bhv::Func)
become!(lk::Link, func, args1...; kwargs...)
```
Cause an actor to change behavior.

# Arguments
- `lk::Link` actor link,
- `bhv`: [`Func`](@ref) implementing the new behavior,
- `func`: callable object,
- `args1...`: (partial) arguments to `func`,
- `kwargs...`: keyword arguments to `func`.
"""
become!(lk::Link, bhv::Func) = send!(lk, Become(bhv))
become!(lk::Link, func, args...; kwargs...) = become!(lk, Func(func, args...; kwargs...))

"""
```
call!(lk::Link, [from::Link,] args2...; timeout::Real=5.0)
```
Call an actor to execute its behavior and to send a 
[`Response`](@ref) with the result. 

# Arguments
- `lk::Link`: actor link, 
- `from::Link`: sender link, 
- `args2...`: remaining arguments to the actor.
- `timeout::Real=5.0`: timeout in seconds.

**Note:** If `from` is omitted, `call!` blocks and returns the result
"""
call!(lk::Link, from::Link, args...) = send!(lk, Call(args, from))
call!(lk::Link, args...; timeout::Real=5.0) = request!(lk, Call, args...; timeout=timeout)
call!(name::Symbol, args...; kwargs...) = call!(whereis(name), args...; kwargs...)

"""
```
cast!(lk::Link, args2...)
```
Cast `args2...` to the actor `lk` to execute its behavior 
without sending a response. 

**Note:** you can prompt the returned value with [`query!`](@ref).
"""
cast!(lk::Link, args...) = send!(lk, Cast(args))

"""
```
exec!(lk::Link, from::Link, func, args...; kwargs...)
exec!(lk::Link, from::Link, f::Func)
exec!(lk::Link, f::Func; timeout::Real=5.0)
```

Ask an actor `lk` (or `name` if registered) to execute an 
arbitrary function and to send the returned value as 
[`Response`](@ref).

# Arguments
- `lk::Link`: actor link,
- `from::Link`: the link a `Response` should be sent to.
- `func`: a callable object,
- `args...; kwargs...`: arguments and keyword arguments to it,
- `fu::Func`: a [`Func`](@ref) with a callable object and
    its arguments,
- `timeout::Real=5.0`: timeout in seconds. Set `timeout=Inf` 
    if you don't want to timeout.

**Note:** If `from` is ommitted, `exec!` blocks, waits and 
returns the result (with a `timeout`).
"""
exec!(lk::Link, from::Link, func, args...; kwargs...) =
    send!(lk, Exec(Func(func, args...; kwargs...), from))
exec!(lk::Link, from::Link, fu::Func) = send!(lk, Exec(fu, from))
exec!(lk::Link, f::Func; timeout::Real=5.0) =
    request!(lk, Exec, f; timeout=timeout)

"""
```
exit!(lk::Link, reason=:ok)
```
Tell an actor `lk` to exit. If it has a [`term`](@ref _ACT) 
function, it calls it with `reason` as last argument. 

!!! note "This behavior is not yet fully implemented!"

    It is needed for supervision.

"""
exit!(lk::Link, reason=:ok) = send!(lk, Exit(reason))

"""
```
init!(lk::Link, func, args...; kwargs...)
```
Tell an actor `lk` to save the `func` with the given 
arguments as an [`init`](@ref _ACT) function and to execute 
it.

The `init` function will be called at actor restart.

!!! note "This behavior is not yet implemented!"

    It is needed for supervision.
"""
init!(lk::Link, f::F, args...; kwargs...) where F<:Function = 
    send!(lk, Init(Func(f, args...; kwargs...)))
init!(name::Symbol, args...; kwargs...) = init!(whereis(name), args...; kwargs...)

"""
```
query!(lk::Link, [from::Link,] s::Symbol; timeout::Real=5.0)
```

Query the `lk` actor about an internal state variable `s`. 

# Parameters
- `lk::Link`: actor link,
- `from::Link`: sender link,
- `s::Symbol` can be one of `:bhv`, `:res`, `:sta`.
- `timeout::Real=5.0`: 

**Note:** If `from` is omitted, `query!` blocks and returns 
the response. In that case there is a `timeout`.


# Examples

```julia
julia> f(x, y; u=0, v=0) = x+y+u+v  # implement a behavior
f (generic function with 1 method)

julia> fact = Actor(f, 1)     # start an actor with it
Channel{Message}(sz_max:32,sz_curr:0)

julia> cast!(fact, 1)         # cast a second parameter to it
YAActL.Cast{Tuple{Int64}}((1,))

julia> query!(fact, :res)     # query the result
2

julia> query!(fact, :bhv)     # query the behavior
f (generic function with 1 method)
```
"""
query!(lk::Link, from::Link, s::Symbol=:sta) = send!(lk, Query(s, from))
query!(lk::Link, s::Symbol=:sta; timeout::Real=5.0) = request!(lk, Query, s, timeout=timeout)
    
"""
```
term!(lk::Link, func, args1...; kwargs...)
```
Tell an actor `lk` to execute `func` with the given partial
arguments when it terminates. This is added by the actor to `args1...` 
when it [`exit!`](@ref)s.

!!! note "This behavior is not yet implemented!"

    It is needed for supervision.
"""
term!(lk::Link, func, args...; kwargs...) = 
    send!(lk, Term(Func(func, args...; kwargs...)))

"""
```
update!(lk::Link, x; s::Symbol=:sta)
update!(lk::Link, arg::Args)
```
Update an actor's internal state `s` with `args...`.

# Arguments
- `lk::Link` an actor link,
- `x`: value/variable to update the choosen state with,
- `arg::Args`: arguments to update,
- `s::Symbol`: can be one of `:sta`, `:dsp`, `:arg`, `:self`, `:name`.

*Note:* If you want to update the stored arguments to the 
behavior function with `s=:arg`, you must pass an [`Args`](@ref) 
to `arg`. If `Args` has keyword arguments, they are merged 
with existing keyword arguments to the behavior function.

# Example
```julia
julia> update!(fact, 5)       # note that fact is in state dispatch
YAActL.Update{Int64}(:sta, 5)

julia> call!(fact, 5)         # call it with 5
10

julia> update!(fact, Args(0, u=5));  # update arguments

julia> call!(fact, 5)         # add the last result, 5 and u=5
20
```
"""
update!(lk::Link, x; s::Symbol=:sta) = send!(lk, Update(s, x))
update!(lk::Link, arg::Args) = send!(lk, Update(:arg, arg))
