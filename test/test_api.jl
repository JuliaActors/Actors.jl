#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#

using Actors, Test

t = Ref{Task}()                # this is for debugging
const sleeptime = 1

arg = Args(1, 2, c=3, d=4)
@test arg.args == (1, 2)
@test arg.kwargs == pairs((c=3, d=4))

a = b = c = d = 1
e = f = 2

incx(x, by; y=0, z=0) = x+y+z + by
subx(x, y, sub; z=0) = x+y+z - sub

me = Actors.newLink()
A = Actors.spawn(Bhv(incx, a, y=b, z=c), taskref=t)
sleep(sleeptime)
@test t[].state == :runnable

# test diag and actor startup, become! (implicitly)
act = request(A, Actors.Diag, :act)
sleep(sleeptime)
@test act.sta == nothing
@test act.bhv.f == incx
@test act.bhv.a == (1,)
@test act.bhv.kw == pairs((y=1,z=1))

# test explicitly become!
become!(A, subx, a, b, z=c)
sleep(sleeptime)
@test act.bhv.f == subx
@test act.bhv.a == (1,1) 
@test act.bhv.kw == pairs((z=1,))

# test update!
update!(A, (1, 2, 3))
sleep(sleeptime)
@test act.sta == (1,2,3)
update!(A, Args(2,3, x=1, y=2), s=:arg)
sleep(sleeptime)
@test act.bhv.a == (2,3)
@test act.bhv.kw == pairs((x=1,y=2,z=1))
update!(A, :dummy, s=:mode)
sleep(sleeptime)
@test act.mode == :dummy
@test A.mode == :dummy

# test query
query(A, me)
@test receive(me).y == (1,2,3)
@test query(A) == (1,2,3)
@test query(A, :res) == nothing
@test query(A, :bhv).f == subx

# test call
become!(A, incx, a, y=b, z=c)
@test call(A, 1) == 4
@test query(A, :res) == 4
@test query(A) == (1,2,3)

# test cast
cast(A, 2)
@test query(A, :res) == 5
update!(A, Args(5, y=1,z=1), s=:arg)
cast(A, 3)
@test query(A, :res) == 10

update!(A, Args(a, y=3,z=3))
cast(A, 3)
@test query(A, :res) == 10
@test query(A) == (1,2,3)

# test exec
exec(A, me, Bhv(cos, 2pi))
@test receive(me).y == 1
exec(A, me, sin, 2pi)
@test receive(me).y == sin(2pi)
@test exec(A, Bhv(cos, 2pi)) == 1
@test exec(A, sin, 2pi) == sin(2pi)

# test init!
init!(A, cos, 2pi)
sleep(sleeptime)
@test act.init.f == cos

# test term!
tvar = [:ndef]
term(x) = tvar[1] = x
term!(A, term)
sleep(sleeptime)
@test act.term.f == term

# test exit!
exit!(A)
sleep(sleeptime)
@test t[].state == :done
@test A.chn.state == :closed
@test tvar[1] == :normal
