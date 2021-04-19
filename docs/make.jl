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
            "tutorial/supervise.md",
        ],
        "How to" => [
            "`spawn` actors"              => "howto/spawn.md",
            "communicate with actors"     => "howto/communicate.md",
            "get information from actors" => "howto/information.md",
            "(not) share variables"       => "howto/share.md",
            "deal with failures"          => "howto/failure.md",
            "`register` actors"           => "howto/register.md",
        ],
        "On Actors" => [
            "manual/basics.md",
            "manual/actors.md",
            "manual/behaviors.md",
            "manual/protocol.md",
            "Error Handling" => [ 
                "manual/errors.md",
                "manual/connections.md",
                "manual/monitors.md",
                "manual/supervisors.md",
                "manual/node_failures.md",
                "manual/checkpoints.md",
                "manual/fault_tolerance.md"
                ],
            "manual/infrastructure.md",
            ],
        "Reference" => [
            "API" => [
                "api/api.md",
                "api/types.md",
                "api/starting.md",
                "api/primitives.md",
                "api/comm.md",
                "api/user_api.md",
                "api/registry.md",
                "api/connect.md",
                "api/monitor.md",
                "api/supervision.md",
                "api/checkpointing.md",
                "api/utils.md",
                "api/diagnosis.md",
                ],
            "Examples" => [
                "examples/dining_phil.md",
                "examples/prod_cons.md",
                "examples/examples.md"
                ],
            "Internals" => [
                "reference/diag.md",
                "reference/internals.md",
                "reference/messages.md",
                "reference/interface.md",
            ],
            "reference/glossary.md",
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
