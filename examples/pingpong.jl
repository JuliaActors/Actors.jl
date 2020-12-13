using Actors, Printf, Random
import Actors: spawn

struct Player{S,T}
    name::S
    capa::T
end

struct Ball{T,S,L}
    diff::T
    name::S
    from::L
end

function (p::Player)(prn, b::Ball)
    if p.capa ≥ b.diff
        send(b.from, Ball(rand(), p.name, self()))
        send(prn, p.name*" serves "*b.name)
    else
        send(prn, p.name*" looses ball from "*b.name)
    end
end
function (p::Player)(prn, ::Val{:serve}, to)
    send(to, Ball(rand(), p.name, self()))
    send(prn, p.name*" serves ")
end

Random.seed!(2020);
prn = spawn(s->print(@sprintf("%s\n", s))) # a print server
ping = spawn(Player("Ping", 0.8), prn)
pong = spawn(Player("Pong", 0.75), prn)

send(ping, Val(:serve), pong);
