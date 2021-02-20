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
            "intro.md",
            "basics.md",
            "actors.md",
            "behaviors.md",
            "protocol.md",
            "Error Handling" => [ 
                "errors.md",
                "connections.md",
                "monitors.md",
                "supervisors.md",
                "checkpoints.md",
                "fault_tolerance.md"
                ],
            "infrastructure.md",
            "glossary.md"
            ],
        "API" => "api.md",
        "Examples" => [
            "examples/dining_phil.md",
            "examples/prod_cons.md",
            "examples/examples.md"
            ],
        "Internals" => [
            "diag.md",
            "internals.md",
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
