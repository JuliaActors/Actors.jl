#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#

# 
# remote node failure detection (RNFD) actor
# ----------------------------------------------
# if an actor on a (relative) remote node is added to a
# supervisor an actor is started scanning the remote link
# in regular intervals. If a ProcessExitedException is
# detected, it notifies the supervisor about it.
# 
const scan_interval = 1.0

struct RNFD{L,S,T}
    sv::L      # supervisor link
    lks::S     # links to remote actors
    pids::T    # supervised pids
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
        filter!(≠(msg.lk), rfd.lks)
        pids = (lk.pid for lk ∈ rdf.lks)
        filter!(∈(pids), rfd.pids)
    end
end
function (rfd::RNFD)(::Scan)
    isempty(rfd.lks) && return nothing
    excs = Int[]
    for lk in rfd.lks
        try
            isready(lk.chn)
        catch exc
            filter!(≠(lk), rfd.lks)
            exc isa ProcessExitedException && push!(excs, exc.worker_id)
        end
    end
    if !isempty(excs)
        filter!(lk->lk.pid ∉ excs, rfd.lks)
        filter!(∉(excs), rfd.pids)
        send(rfd.sv, NodeFailure(unique(excs)))
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

# 
# get a link to the RNFD actor, create it if it doesn't exist.
#
function rnfd(s::Supervisor)
    i = findfirst(c->c.lk.mode == :rnfd, s.childs)
    return !isnothing(i) ? s.childs[i].lk : rnfd_start(self())
end
rnfd_exists(s::Supervisor) = !isnothing(findfirst(c->c.lk.mode == :rnfd, s.childs))
#
# add a remote child to an RNFD actor, 
# create if first if it doesn't exist.
#
rnfd_add(s::Supervisor, child::Link) = send(rnfd(s), Add(child))

