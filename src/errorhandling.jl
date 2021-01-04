#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#

const ERR_BUF = 10

_terminate!(A::_ACT, reason) = isnothing(A.term) || Base.invokelatest(A.term.f, reason)

"""
    trapExit(lk::Link=self())

Change the mode of an actor to `:system`.

A `:system` actor does not stop if it receives an 
[`Exit`](@ref) signal and does not propagate it
further. Instead it reports the failure and saves a
link to the failed actor. 

See [`diag`](@ref) for getting links to failed actors 
from a `:system` actor.
"""
trapExit(lk::Link=self()) = send(lk, Update(:mode, :system))

function saveerror(lk::Link)
    try
        err = task_local_storage("_ERR")
    catch exc
        exc isa KeyError ?
            err = task_local_storage("_ERR", Link[]) :
            rethrow()
    end
    length(err) ≥ ERR_BUF && popfirst!(err)
    push!(lk)
end
function errored()
    try
        return task_local_storage("_ERR")
    catch exc
        exc isa KeyError && return nothing
        rethrow()
    end
end

function onerror(A::_ACT, exc)
    for c in A.conn
        c isa Parent ?
            send(c.lk, Exit(self(), exc, self(), A)) :
            send(c.lk, Exit(self(), exc, self(), nothing))
    end
end
