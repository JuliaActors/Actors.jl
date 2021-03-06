#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#

using Actors
import Actors: spawn

greet(greeting, msg) = greeting*", "*msg*"!"

hello(greeter, to) = request(greeter, to)

greeter = spawn(Bhv(greet, "Hello"))

sayhello = spawn(Bhv(hello, greeter))

request(sayhello, "World")

request(sayhello, "Kermit")
