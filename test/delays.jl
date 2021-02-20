#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#

module Delays

using Actors
import Actors: newLink

macro delayed(expr, timeout)
    return quote
        timedwait($timeout) do 
            try
                return $(esc(expr))
            catch
                return false
            end
        end
        $(esc(expr))
    end 
end

macro delayed(expr)
    return :(@delayed $(esc(expr)) 1)
end

function Base.:(==)(l1::L, l2::L) where L <:Link
    return l1.chn == l2.chn && l1.pid == l2.pid && l1.mode == l2.mode
end
Base.:(==)(t1::R, t2::R) where R<:Base.RefValue{Task} = t1[] == t2[]

Base.copy(rt::Base.RefValue{Task}) = Ref(rt[])
function Base.copy(lk::Link) 
    lk1 = newLink()
    lk1.chn  = lk.chn
    lk1.pid  = lk.pid
    lk1.mode = lk.mode
    return lk1
end

function changed(var, timeout=1)
    oldvar = copy(var)
    timedwait(timeout) do 
        oldvar != var
    end
    return var
end

export @delayed, changed

end # Delays
