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
    if msg.lk ∈ rfd.lks
        filter!(≠(msg.lk), rfd.lks)
        pids = (lk.pid for lk ∈ rfd.lks)
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
        filter!(p->p ∉ excs, rfd.pids)
        send(rfd.sv, NodeFailure(unique(excs)))
    end
end

#
# Supervisor behavior for NodeFailure
#

# 
# remove temporary childs from both s and fchilds
#
function remove_temporary!(s, fchilds)
    act = task_local_storage("_ACT")
    filter!(fchilds) do child
        if child.info.restart == :temporary
            log_warn("temporary actor $(isnothing(child.name) ? :noname : child.name) failed, $(ProcessExitedException(child.lk.pid))")
            filter!(c->c.lk!=child.lk, act.conn)
            filter!(c->c.lk!=child.lk, s.childs)
            return false
        else
            return true
        end
    end
end
function restart_child!(c::Child, pid::Int)
    log_warn("supervisor: restarting child $(isnothing(c.name) ? :noname : c.name) on pid $pid")
    if c.lk isa Link
        lk = !isnothing(c.start) ? c.start(pid) : spawn(c.init; pid)
        c.lk.chn = lk.chn
        c.lk.pid = lk.pid
        isnothing(c.name) || update!(lk, c.name, s=:name)
    end
end
function restart!(s::Supervisor, cs::Vector{Child}, pids::Vector{Int})
    if s.option[:strategy] == :one_for_one
        for (i, c) in enumerate(cs)
            restart_child!(c, pids[i])
            rnfd_add(s, c.lk)
        end
    elseif s.option[:strategy] == :one_for_all
        log_warn("supervisor: restarting all")
        for child in s.childs
            child ∈ cs ?
                begin 
                    restart_child!(child, pids[findfirst(==(child),cs)]) 
                    rnfd_add(s, child.lk)
                end :
                child.lk.mode ≠ :rnfd && shutdown_restart_child!(child)
        end
    else
        log_warn("supervisor: restarting rest")
        ix = findfirst(c->c ∈ cs, s.childs)
        for child in s.childs[ix:end]
            child ∈ cs ?
                begin
                    restart_child!(child, pids[findfirst(==(child),cs)]) 
                    rnfd_add(s, child.lk)
                end :
                child.lk.mode ≠ :rnfd && shutdown_restart_child!(child)
        end
    end
end
#
# return spare pids for failed childs cs and delete them from
# the s.option[:spares] dict entry
#
function spare_pids!(s::Supervisor, cs)
    spares = if haskey(s.option, :spares) && !isempty(s.option[:spares])
        s.option[:spares]
    else
        used = unique(map(c->c.lk.pid, s.childs))
        filter(p->p ∉ used, reverse(procs()))
    end
    filter!(p->p ∈ procs(), spares)
    pids = map(c->c.lk.pid, cs)
    p_old = sort(unique(pids))
    if length(p_old) ≤ length(spares)
        p_new = spares[1:length(p_old)]
        rp = [p_old[i]=>p_new[i] for i ∈ 1:length(p_old)]
        replace!(pids, rp...)
    elseif !isempty(spares)
        pids = rand(spares, length(pids))
    else
        pids = rand(procs(), length(pids))
    end
    haskey(s.option, :spares) && filter!(p->p ∉ pids, s.option[:spares])
    return pids
end
function (s::Supervisor)(msg::NodeFailure)
    foreach(msg.pids) do pid
        log_warn("supervisor: Process $pid exited!")
    end
    failed_childs = filter(c->c.lk.pid ∈ msg.pids, s.childs)
    remove_temporary!(s, failed_childs)
    if !isempty(failed_childs)
        if restart_limit!(s)
            log_warn("supervisor: restart limit $(s.option[:max_restarts]) exceeded!")
            send(self(), Exit(:shutdown, fill(nothing, 3)...))
        else
            restart!(s, failed_childs, spare_pids!(s, failed_childs))
        end
    end
end

#
# RNFD API
#
"""
    rnfd_start(sv::Link;; interval=1, kwargs...)

Start a RNFD actor and return a link to it.

# Arguments
- `sv::Link`: supervisor to the actor,
- `interval=1`: interval in seconds for checking remote nodes.
"""
function rnfd_start(sv::Link; interval=1, kwargs...)
    lk = spawn(RNFD(sv, Link[], Int[]); mode = :rnfd, kwargs...)
    exec(lk, supervise, sv)
    timer = Timer(interval; interval) do t
        send(lk, Scan())
    end
    term!(lk, (exp)->close(timer))
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
# create it first if it doesn't exist.
#
rnfd_add(s::Supervisor, child::Link) = send(rnfd(s), Add(child))

