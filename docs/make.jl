using Documenter, Actors

makedocs(
    modules = [Actors],
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true",
        collapselevel=1,
        ),
    sitename = "Actors.jl",
    authors  = "Paul Bayer",
    pages = [
        "Actors Documentation" => "index.md",
        "Manual" => [
            "Getting started" => "intro.md",
            "Basics" => "basics.md",
            "Actors" => "actors.md",
            "Behaviors" => "behaviors.md",
            "Protocol" => "protocol.md",
            "Infrastructure" => "infrastructure.md",
            "Glossary" => "glossary.md"
            ],
        "API" => "api.md",
        "Examples" => "examples.md",
        "Internals" => [
            "messages.md",
            "interface.md",
        ]
    ]
)

deploydocs(
    repo   = "github.com/JuliaActors/Actors.jl.git",
    target = "build",
    deps   = nothing,
    make   = nothing,
    devbranch = "master",
    devurl = "dev",
    versions = ["stable" => "v^", "v#.#", "dev" => "dev"]
)
