#
# This file is part of the YAActL.jl Julia package, MIT license
#
# Paul Bayer, 2020
#

"""
	info(lk::Link)

Return the state of an actor associated with `lk`:

- `Actors.Info` if it is runnable,
- `:done` if it has finished,
- else return the failed task. 
"""
function info(lk::Link{Channel{Any}})
	!isnothing(lk.chn.excp) ?
		hasfield(typeof(lk.chn.excp), :task) ? 
			lk.chn.excp.task : 
			:done :
		diag(lk, :info)
end
function info(lk::Link{RemoteChannel{Channel{Any}}})
	return try
		diag(lk, :info)
	catch exc
		!hasfield(typeof(exc), :captured) ? exc :
		exc.captured.ex isa InvalidStateException ? :done :
			exc.captured.ex.task
	end
end
info(name::Symbol) = info(whereis(name))

function pretty(i::Info) 
s = """
Actor    $(i.mode)
Behavior $(i.bhvf)
Pid      $(i.pid), Thread $(i.thrd)
Task     @0x$(string(i.task, base = 16, pad = Sys.WORD_SIZE>>2))
Ident    $(i.tid)
"""
return isnothing(i.name) ? s : s*"Name     $(i.name)"
end

Base.show(io::IO, i::Info) = print(io, pretty(i))

"""
```
diag(lk::Link, check::Symbol=:state)
diag(name::Symbol, ....)
```
Diagnose an actor, get a state or stacktrace.

# Arguments
- `lk::Link`: actor link,
- `check::Symbol`: requested information,
	- `:state`: returns `:ok` if the actor is running, 
	- `:task`: returns the current actor task,
	- `:tid`: current actor task encoded as a proquint string,
	- `:pid`: process identifier number,
	- `:act`: actor `_ACT` variable,
	- `:info`: actor [`Info`](@ref),
	- `:err`: error log (only monitors or supervisors).
- `timeout::Real=5.0`: timeout in seconds.

!!! warning "This is for diagnosis only!"

	Modifying an actor's state can cause a race condition.
"""
diag(lk::Link, check::Symbol=:state; timeout::Real=5.0) = request(lk, Diag, check; timeout)
diag(name::Symbol, args...; kwargs...) = diag(whereis(name), args...; kwargs)
