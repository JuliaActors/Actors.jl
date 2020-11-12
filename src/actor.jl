#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#

"""
    _ACT()

Internal actor status variable.

# Fields

1. `bhv::Func` : the behavior function and its internal arguments,
2. `init::Func`: the init function and its arguments,
3. `term::Func`: the terminate function and its arguments,
4. `self::Link`: the actor's (local or remote) self,
5. `name::Symbol`: the actor's registered name.
6. `res::Any`: the result of the last behavior execution,
7. `usr::Any`: user variable for plugging in something.

see also: [`Func`](@ref), [`Link`](@ref)
"""
mutable struct _ACT
    bhv::Func
    init::Union{Nothing,Func}
    term::Union{Nothing,Func}
    self::Union{Nothing,Link}
    name::Union{Nothing,Symbol}
    res::Any
    usr::Any

    _ACT() = new(Func(+), fill(nothing, 6)...)
end

onmessage(A::_ACT, msg::Become) = A.bhv = msg.x
onmessage(A::_ACT, msg::Diag) = send!(msg.from, A)
onmessage(A::_ACT, msg::Msg) = A.res = A.bhv.f((A.bhv.args..., msg)...; A.bhv.kwargs...)
onmessage(A::_ACT, msg::Update) = onmessage(A, msg, Val(msg.s))
onmessage(A::_ACT, msg) = A.res = A.bhv.f((A.bhv.args..., msg...)...; A.bhv.kwargs...)

# dispatch on Update message
onmessage(A::_ACT, msg::Update, ::Val{:self}) = A.self = msg.x
onmessage(A::_ACT, msg::Update, x) = nothing

# this is the actor loop
function _act(ch::Channel)
    A = _ACT()
    task_local_storage("_ACT", A)
    while true
        msg = take!(ch)
        onmessage(A, msg)
        msg isa Exit && break
    end
    isnothing(A.name) || call!(_REG, unregister, A.name)
end


function spawn(bhv::Func; pid=myid(), thrd=false, sticky=false, taskref=nothing)
    if pid == myid()
        lk = Link(32)
        if Bool(thrd) && thrd in 1:nthreads()
            spawnonthread(thrd, lk, taskref)
            @threads for i in 1:nthreads()
                if i == thrd 
                    t = @async _act(lk)
                    isnothing(taskref) || (taskref[] = t)
                    bind(lk.chn, t)
                end
            end
        else
            t = Task(()->_act(lk.chn))
            isnothing(taskref) || (taskref[] = t)
            pid == 1 && (t.sticky = sticky)
            bind(lk.chn, t)
            schedule(t)
        end
    else
        lk = Link(RemoteChannel(()->Channel(func, size), pid),
                  pid, :remote)
    end
    # put!(lk.chn, Update(:self, lk))
    become!(lk, bhv)
    return lk
end
spawn(m::Val{:Actors}, args...; kwargs...) = spawn(args...; kwargs...)
spawn(m::Module, args...; kwargs...) = spawn(Val(first(fullname(m))), args...; kwargs...)

become!(lk::Link, bhv::Func) = send!(lk, Become(bhv))
become!(lk::Link, func, args...; kwargs...) = become!(lk, Func(func, args...; kwargs...))

self() = task_local_storage("_ACT").self

function become(bhv, args...; kwargs...)
    act = task_local_storage("_ACT")
    act.bhv = Func(bhv, args...; kwargs...)
end
