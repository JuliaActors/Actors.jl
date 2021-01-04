#
# This file is part of the YAActL.jl Julia package, MIT license
#
# Paul Bayer, 2020
#

"""
	istaskfailed(lk::Link)

Returns true if a task associated with `lk` has failed.
"""
Base.istaskfailed(lk::Link) = !isnothing(lk.chn.excp)

"""
	info(lk::Link)

Return the state (eventually the stacktrace) of a task associated 
with `lk`.
"""
function info(lk::Link)
	if istaskfailed(lk)
		return hasfield(typeof(lk.chn.excp), :task) ? lk.chn.excp.task : lk.chn.excp
	else
		return lk.chn.cond_take.waitq.head.donenotify.waitq.head.code.task.state
	end
end
info(lks::Array{Link,1}) = foreach(lk->show(info(lk)), lks)

"""
```
diag(lk::Link, check=0)
diag(name::Symbol, ....)
```
Give an actor state or stacktrace.

If `check != 0` return the internal `_ACT` variable of the 
actor. This is for diagnosis and testing only!
"""
diag(lk::Link, check=0) = request(lk, Diag, check)
diag(name::Symbol, args...) = diag(whereis(name), args...)
