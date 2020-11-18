#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#

using Actors, Test

t = Ref{Task}()                # this is for debugging
const sleeptime = 0.2

arg = Args(1, 2, c=3, d=4)
@test arg.args == (1, 2)
@test arg.kwargs == pairs((c=3, d=4))

a = b = c = d = 1
e = f = 2

incx(x, by; y=0, z=0) = x+y+z + by
subx(x, y, sub; z=0) = x+y+z - sub

A = Actors.spawn(Func(incx, a, y=b, z=c), taskref=t)
sleep(sleeptime)
@test t[].state == :runnable

# test diag and actor startup, become! (implicitly)
act = request!(A, Actors.Diag, 1)
sleep(sleeptime)
@test act.sta == nothing
@test act.bhv.f == incx
@test act.bhv.args == (1,)
@test act.bhv.kwargs == pairs((y=1,z=1))

# test explicitly become!
become!(A, subx, a, b, z=c)
sleep(sleeptime)
@test act.bhv.f == subx
@test act.bhv.args == (1,1) 
@test act.bhv.kwargs == pairs((z=1,))

# test update!
update!(A, (1, 2, 3))
sleep(sleeptime)
@test act.sta == (1,2,3)
update!(A, Args(2,3, x=1, y=2), s=:arg)
sleep(sleeptime)
@test act.bhv.args == (2,3)
@test act.bhv.kwargs == pairs((x=1,y=2,z=1))

# test query!
@test query!(A) == (1,2,3)
@test query!(A, :res) == nothing
@test query!(A, :bhv).f == subx

# test call!
become!(A, incx, a, y=b, z=c)
@test call!(A, 1) == 4
@test query!(A, :res) == 4
@test query!(A) == (1,2,3)

# test cast!
cast!(A, 2)
@test query!(A, :res) == 5
update!(A, Args(5, y=1,z=1), s=:arg)
cast!(A, 3)
@test query!(A, :res) == 10

update!(A, Args(a, y=3,z=3), s=:arg)
cast!(A, 3)
@test query!(A, :res) == 10
@test query!(A) == (1,2,3)

# test exec!
@test exec!(A, Func(cos, 2pi)) == 1

# test exit!
exit!(A)
sleep(sleeptime)
@test t[].state == :done
@test A.chn.state == :closed
