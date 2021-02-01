#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#

const _WARN = [true]

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
        @warn s
        enable_finalizers(true)
    end
end
