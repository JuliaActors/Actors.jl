using Documenter, Actors

makedocs(
    modules = [Actors],
    format = Documenter.HTML(prettyurls = get(ENV, "CI", nothing) == "true"),
    sitename = "Actors.jl",
    authors  = "Paul Bayer",
    pages = [
        "Home" => "index.md",
        "Introduction" => "intro.md",
        "Actors" => "actors.md",
        "Behaviors" => "behaviors.md",
        "Actor API" => "api.md",
        "Examples" => "examples.md",
        "Internals" => [
            "interface.md",
            "protocol.md",
            "diagnosis.md"
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
