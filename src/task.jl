#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#

"The actor task type."
struct ATask{X,Y}
    t::X
    back::Y
end

"""
    async(func::Func; pid=myid(), thrd=false, sticky=false, taskref=nothing)

Start a task to execute `func` and return an [`ATask`](@ref) 
variable.

An actor task sends its result to the `back` link 
of the `ATask` variable and exits immediately.

# Parameters
- `func::Func`: 
- `pid=myid()`: 
- `thrd=false`: 
- `sticky=false`: 
- `taskref=nothing`: 
"""
function async(func::Func; pid=myid(), thrd=false, sticky=false, taskref=nothing)
    lk = pid == myid() ? newLink(1) : newLink(1, remote=true)
    task = spawn(func, pid=pid, thrd=thrd, sticky=sticky, taskref=taskref)
    call(task, lk)
    exit!(task)
    return ATask(task, lk)
end

"""
    await(t::ATask; timeout::Real=5.0)

Await a task reply and return it.
"""
await(t::ATask; timeout::Real=5.0) = receive(t.back, timeout=timeout).y
