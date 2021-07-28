# Actors demo

Actors in Julia! Let's do a quick demo.

An actor takes a function as behavior. Here I have a function **`inc!`**, to increment a variable `a` with a parameter `c`.

We spawn our **actor** with the `inc!` behavior function give it the first parameter of value 0 as an **acquaintance**.

That gives us a **link** back, which wraps a Julia **Channel**.

Over that we can send it messages using the Actors API. We see that it even has a name, albeit a strange one.

Now we can repeatedly **call** the actor with the yet missing communication parameter `c` and get a result back. 

We see that this is a **stateful** communication. Each computation gives us a different result. Our actor has **state**. 

Now I **change its behavior** to **`dinc!`**.

With that it serves a **dictionary**. We give it an **empty** dictionary as acquaintance. It now will increment a dictionary entry when a message with a key value pair arrives.

Then we send it **1_000** messages times concurrently from tasks on all available cores. 

If we now call our actor without arguments, we get back the dictionary showing how often our actor has received a message from each core.

Out actor has **serialised** the asynchronous messages. So there was no race condition and all sums up to 1_000.

Fine!

But, **stop!** That was **one** actor. How about **thousands** of them?

In order to demonstrate to you that actors are lightweight, I have that **link** behavior which takes a link, receives a message and sends it incremented back to that link. We **compose** those link actors into a **chain** of arbitrary length, send the last one a message and wait for the message coming back to the first one.

Thus we can **measure** how long does it take to spawn n actors and pushing a message through them.

We see that it takes about 20 ms for **1_000** multi-threaded actors. That means about **20 µs** to start **one** actor, receive and send a message and to stop. This takes longer than to start a simple task since some messaging is involved. But that will yet improve with development.

# Julia as an actor

Let me give you a glimpse into a possible future of Julia actors and show you why I think it should be developed. Actors can scale in functionality and across computers and languages, and therefore I asked myself if I could wrap **Julia** into an actor and serve it to Erlang or Elixir clients in a network.

I wrote an experimental package `Erjulix` which lets Erlang, Julia and Elixir communicate over UDP sockets. Surprisingly it takes only three types of messages to serve Julia's functionality: `eval` (parse), `call` and `set`.

Let's try it out: In a Julia session I spawn a  task which listens to UDP socket 6000 and starts another `evalServer` actor on demand.

Then from the Elixir REPL I use the Erlang module on the left side to ask Julia for an `evalServer`. We can see that Julia spawned an actor listening to a new socket and created a temporary module for it.

Now we can let the Julia `evalServer` evaluate commands from the Elixir side. Here we see that it is running on thread 3. Next we call a factorial from it. Let's try it with 50. Now we get an error message from Julia. Therefore we request the Julia server to create a new function that can calculate such big factorials. And then we can call that and get another big number.

You may be interested how long such an interaction between Julia and Erlang does take on my machine. We time it with Erlang and see that it takes about 500 µs.

How long may such an interaction take with a remote machine? Let's try the same from the PI besides my desk. We give Elixir on the little PI the `EvalServer`'s address and we see that it takes the PI about 24 ms to get the big factorial from Julia over the network. That's not bad either.
