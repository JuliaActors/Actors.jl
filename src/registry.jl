#
# This file is part of the YAActL.jl Julia package, MIT license
#
# Paul Bayer, 2020
#
# It implements the Actor-model
#

# --------------------------------
# registry API
# --------------------------------

"""
    register(name::Symbol, lk::Link)

Register the actor `lk` with `name`. Returns `true` if the 
registration succeeds, `false` if `name` is already in use.
"""
function register(name::Symbol, lk::Link) 
    res = myid() == 1 ?
        call(_REG, register, name, lk) :
        call(_REG, register, name, Link(RemoteChannel(()->lk.chn),myid(),:remote))
    update!(lk, name, s=:name)
    return res
end

"""
    unregister(name::Symbol)

Remove any registrations associated with `name`.
"""
function unregister(name::Symbol)
    lk = whereis(name)
    if !ismissing(lk)
        call(_REG, unregister, name)
        update!(lk, nothing, s=:name)
    end
end

"""
    whereis(name::Symbol)

Find out whether name is registered. Return the actor link 
`lk` or `missing` if not found.
"""
whereis(name::Symbol) = call(_REG, whereis, name)

"""
    registered()

Return an Array of all registered actors in the system.
"""
registered() = call(_REG, registered, myid())

# behavior functions  
function _reg(d::Dict{Symbol,Link}, ::typeof(register), name::Symbol, lk::L) where L<:Link
    if !haskey(d, name)
        d[name] = lk
        return true
    else
        return false
    end
end
_reg(d::Dict{Symbol,Link}, ::typeof(unregister), name::Symbol) = delete!(d, name)
_reg(d::Dict{Symbol,Link}, ::typeof(whereis), name::Symbol) = get(d, name, missing)
_reg(d::Dict{Symbol,Link}, ::typeof(registered), id::Int) = 
    id == 1 ?   collect(pairs(d)) :
                [Pair(i[1], _rlink(i[2])) for i in pairs(d)]
_reg(d::Dict{Symbol,Link}, ::typeof(empty!)) = empty!(d)
