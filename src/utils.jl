#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#

"""
    @msg [Msg] A B C

Define empty structs as message types. `Msg` is an
existing abstract datatype.

To call `@msg Msg A B C` is equivalent to
```
struct A <: Msg end
struct B <: Msg end
struct C <: Msg end
```

To call `@msg D E F` is equivalent to
```
struct D end
struct E end
struct F end
```
"""
macro msg(syms...)
    isempty(syms) && throw(ArgumentError("no arguments given for msg"))

    dt = syms[1]
    subtype = false
    if isa(dt, Symbol)
        try
            dt = Core.eval(__module__, dt)
            if isabstracttype(dt)
                subtype = true
                if length(syms) > 1
                    syms = syms[2:end]
                else
                    throw(ArgumentError("no arguments given for \"$dt\""))
                end
            end
        catch exc
            exc isa UndefVarError || rethrow()
        end
    else
        throw(ArgumentError("\"$dt\" is not a symbol"))
    end
    n = Symbol[]
    for s in syms
        isa(s, Symbol) || throw(ArgumentError("\"$s\" is not a symbol"))
        Base.isidentifier(s) || throw(ArgumentError("\"$s\" is not a valid identifier"))
        s in n && throw(ArgumentError("name \"$s\" is not unique"))
        push!(n, s)
    end
    for m in n
        subtype ?
            Core.eval(__module__, :(struct $m <: $dt end)) :
            Core.eval(__module__, :(struct $m end))
    end
end

"""
    tid(n::Int)

Return a threadid where an `n`-th calculation could run.

This is for emulating a `@threads for` loop with actors.
"""
tid(n::Int) = t = n % nthreads() == 0 ? nthreads() : t
