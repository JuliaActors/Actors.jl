#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#

const _WARN = [true]

function warn(msg::Down)
    if _WARN[1]
        enable_finalizers(false)
        if msg.reason isa Exception
            @warn "Down: $(msg.task), $(msg.task.exception)"
        else
            @warn "Down: $(msg.reason)"
        end
        enable_finalizers(true)
    end
end
function warn(msg::Exit)
    if _WARN[1]
        enable_finalizers(false)
        if msg.reason isa Exception && !isnothing(msg.task.exception)
            t = msg.task
            @warn "Exit: $t, $(t.exception)"
        else
            @warn "Exit: $(msg.reason)"
        end
        enable_finalizers(true)
    end
end
