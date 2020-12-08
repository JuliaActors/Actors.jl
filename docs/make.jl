using Documenter, Actors

makedocs(
    modules = [Actors],
    format = Documenter.HTML(prettyurls = get(ENV, "CI", nothing) == "true"),
    sitename = "Actors.jl",
    authors  = "Paul Bayer",
    pages = [
        "Home" => "index.md",
        "Introduction" => "intro.md",
        "Basics" => "basics.md",
        "Actors" => "actors.md",
        "Behaviors" => "behaviors.md",
        "Protocol" => "protocol.md",
        "Infrastructure" => "infrastructure.md",
        "Actor API" => "api.md",
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
