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
        "Introduction" => "index.md",
        "Tutorials" => [
            "tutorial/install.md",
            "tutorial/intro.md",
            "tutorial/tabletennis.md",
            "tutorial/stack.md",
            "tutorial/dictsrv.md",
        ],
        "How to" => [
            "`spawn` actors"              => "howto/spawn.md",
            "communicate with actors"     => "howto/communicate.md",
            "get information from actors" => "howto/information.md",
            "`connect` actors"            => "howto/connect.md",
            "`monitor` actors"            => "howto/monitor.md",
            "`supervise` actors"          => "howto/supervise.md",
            "`register` actors"           => "howto/register.md",
        ],
        "On Actors" => [
            "basics.md",
            "actors.md",
            "behaviors.md",
            "protocol.md",
            "Error Handling" => [ 
                "errors.md",
                "connections.md",
                "monitors.md",
                "supervisors.md",
                "node_failures.md",
                "checkpoints.md",
                "fault_tolerance.md"
                ],
            "infrastructure.md",
            ],
        "Reference" => [
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
            ],
            "glossary.md",
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
