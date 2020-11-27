using Actors
import Actors: spawn

greet(greeting, msg) = greeting*", "*msg*"!"

hello(greeter, to) = request(greeter, to)

greeter = spawn(Func(greet, "Hello"))

sayhello = spawn(Func(hello, greeter))

request(sayhello, "World")

request(sayhello, "Kermit")
