#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#

# 
# remote node failure detection
# 
const scan_interval = 1.0

struct RNFD{L,S,T}
    sv::L
    lks::S
    pids::T
end
struct Add{L}
    lk::L
end
struct Remove{L}
    lk::L
end
struct Scan end

# 
# RNFD behavior
# 
function (rfd::RNFD)(msg::Add)
    if msg.lk ∉ rfd.lks
        push!(rfd.lks, msg.lk)
        msg.lk.pid ∈ rfd.pids || push!(rfd.pids, msg.lk.pid)
    end
end
function (rfd::RNFD)(msg::Remove)
    if msg.lk ∈ rdf.lks
        filter!(!=(msg.lk), rfd.lks)
        pids = (lk.pid for lk ∈ rdf.lks)
        filter!(p->p ∈ pids, rfd.pids)
    end
end
function (rfd::RNFD)(::Scan)
    isempty(rfd.lks) && return nothing
    excs = Exception[]
    for lk in rfd.lks
        ex = try
            isready(lk.chn)
        catch exc
            filter!(!=(lk), rfd.lks)
            exc isa ProcessExitedException ? exc : false
        end
        ex isa Bool || push!(excs, ex)
    end
    if !isempty(excs)
        for pex ∈ unique(x->x.worker_id, excs)
            if pex.worker_id ∈ rfd.pids
                send(rfd.sv, Exit(pex, self(), nothing, nothing))
                filter!(!=(pex.worker_id), rfd.pids)
            end
        end
    end
end

"""
    rnfd_start(sv::Link;; interval=1, kwargs...)

Start a RNFD actor and return a link to it.

# Arguments
- `sv::Link`: supervisor to the actor,
- `interval=1`: interval in seconds for checking remote nodes.
"""
function rnfd_start(sv::Link; interval=1, kwargs...)
    lk = spawn(RNFD(sv, Link[], Int[]); kwargs...)
    lk.mode = :rnfd
    exec(lk, supervise, sv)
    timer = Timer(interval; interval) do t
        send(lk, Scan())
    end
    term!(lk, ()->close(timer))
    return lk
end


