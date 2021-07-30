# Some Actor Links

Links and references used in the Juliacon 21 talk:

## History of Actors, Actor Model

- Dr. Alan Kay on the [meaning of “object-oriented programming”](http://www.purl.org/stefan_ram/pub/doc_kay_oop_de)
- Joe Armstrong & Alan Kay - [Joe Armstrong interviews Alan Kay](https://www.youtube.com/watch?v=fhOHn9TClXY)
- Wikipedia entry on the [Actor Model](https://en.wikipedia.org/wiki/Actor_model)
- Carl Hewitt, [Actor Model of Computation for Scalable Robust Information Systems](https://hal.archives-ouvertes.fr/hal-01163534v7/document)
- Hewitt, Meijer and Szyperski: [The Actor Model (everything you wanted to know, but were afraid to ask)](https://channel9.msdn.com/Shows/Going+Deep/Hewitt-Meijer-and-Szyperski-The-Actor-Model-everything-you-wanted-to-know-but-were-afraid-to-ask)

The latter is a great and fun introduction to some basic ideas of the Actor Model.

## Erlang/OTP

- On the relation between the Actor Model and Erlang/OTP: [What does the actor belong to?](https://elixirforum.com/t/what-does-the-actor-belong-to/34590)

This shows that Erlang is no direct descendant of the Actor Model but was based on a practical approach generating very similar conclusions.

- see: [Making reliable distributed systems in the presence of software errors](https://erlang.org/download/armstrong_thesis_2003.pdf), PhD thesis of Joe Armstrong, Erlang’s co-inventor, describing the origins of Erlang.

## Actors in Julia

Thus a Julian approach to Actors can inherit from both traditions: the more theoretical Actor Model approach and the practical and very mature Erlang/OTP story and ecosystem.

- The [`Actors.jl` documentation](https://juliaactors.github.io/Actors.jl/dev) gives further explanations and links on Actors,
- [`erjulix`](https://github.com/pbayer/erjulix): experimental module to connect Erlang, Julia, Elixir,
- the [`JuliaActors`](https://github.com/JuliaActors) GitHub organization,
- [`Circo`](https://github.com/Circo-dev/Circo): another Julian take on actors.
