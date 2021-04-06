#
# This file is part of the Actors.jl Julia package, MIT license
#
# Paul Bayer, 2020
#

using Actors, Distributed, Test
import Actors: spawn

length(procs()) == 1 && addprocs(1)

@everywhere using Actors
@everywhere function ident(id, from)
    id == from ?
        ("local actor",  id, from) :
        ("remote actor", id, from)
end
call(Actors._REG, empty!)

# 
# test registry with one local actor
#
@test register(:act1, spawn(Bhv(ident, 1)))
a1 = Actors.diag(:act1, :act)
@test a1.name == :act1  # does it have its name ?
@test call(:act1, myid()) == ("local actor", 1, 1)
act1 = whereis(:act1)
unregister(:act1)
sleep(0.1)
@test isnothing(a1.name) # did it delete the name ?
@test isempty(registered())
@test register(:act1, act1)
sleep(0.1)
@test length(registered()) == 1
exit!(:act1)
sleep(0.1)
@test act1.chn.state == :closed
@test isempty(registered()) # did it unregister at exit ?
# 
# test registry across workers
# 
@test register(:act1, spawn(Bhv(ident, 1)))
@test register(:act2, spawn(Bhv(ident, 2), pid=2))
@test call(:act2, myid()) == ("remote actor", 2, 1)
@test fetch(@spawnat 2 call(:act1, myid())) == ("remote actor", 1, 2)
@test fetch(@spawnat 2 call(:act2, myid())) == ("local actor", 2, 2)
@test whereis(:act1).pid == 1
@test whereis(:act2).pid == 2
@test fetch(@spawnat 2 whereis(:act1)).pid == 1
@test fetch(@spawnat 2 whereis(:act2)).pid == 2
let
    r = registered()
    l = [i[1] for i in r]
    @test length(r) == 2
    @test :act1 in l
    @test :act2 in l
    r = fetch(@spawnat 2 registered())
    @test length(r) == 2
    @test all([i[2].chn for i in r]) do x
        x isa RemoteChannel
    end
end
unregister(:act1)
unregister(:act2)
@test isempty(registered())
# 
# test API functions with registered actors
# 
f(a, b) = a + b
@test register(:act1, spawn(Bhv(f, 1)))
@test !register(:act1, spawn(f, 2))
a1 = Actors.diag(:act1, :act)
send(:act1, Actors.Cast((1,)))
sleep(0.1)
@test a1.res == 2
@test request(:act1, Actors.Call, 2) == 3
become!(:act1, f, 0)
@test call(:act1, 1) == 1
cast(:act1, 2)
sleep(0.1)
@test a1.res == 2
@test exec(:act1, Bhv(f, 5, 5)) == 10
@test query(:act1, :res) == 2
init!(:act1, cos, 2pi)
sleep(0.1)
@test a1.init.f == cos
term!(:act1, cos, 2pi)
sleep(0.1)
@test a1.term.f == cos
sleep(0.1)
update!(:act1, 10)
sleep(0.1)
@test a1.sta == 10 
unregister(:act1)
