#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#

#
# the following is needed for giving a warning from a thread. 
# see: https://github.com/JuliaLang/julia/issues/35689
# 
enable_finalizers(on::Bool) = ccall(:jl_gc_enable_finalizers, Cvoid, (Ptr{Cvoid}, Int32,), Core.getptls(), on)

const date_format = "yyyy-mm-dd HH:MM:SS"
const _WARN = [true]

tid(t::Task=current_task()) = convert(UInt, pointer_from_objref(t))
pqtid(t::Task=current_task()) = uint2quint(tid(t), short=true)

function warn(msg::Down, info::String="")
    warn(msg.reason isa Exception ?
            "Down: $info $(msg.task), $(msg.task.exception)" :
            "Down: $info $(msg.reason)")
end
function warn(msg::Exit, info::String="")
    warn(msg.reason isa Exception && !isnothing(msg.task.exception) ?
            "Exit: $info $(msg.task), $(msg.task.exception)" :
            "Exit: $info $(msg.reason)")
end
function warn(s::String)
    if _WARN[1]
        enable_finalizers(false)
        @warn "$(Dates.format(now(), date_format)) $(pqtid()): $s"
        enable_finalizers(true)
    end
end
