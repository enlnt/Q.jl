using Documenter
push!(LOAD_PATH, joinpath(@__DIR__, "../src/"))
using JuQ

makedocs(
    modules   = [JuQ, JuQ._k],
    format    = :html,
    sitename  = "JuQ - Julia for kdb+",
    linkcheck = true,
    pages = [
        "Home" => "index.md",
        "Manual" => [
            "manual/common-api.md",
            "manual/client.md",
            "manual/server.md",
            "manual/low-level.md",
        ]
    ],
)

deploydocs(
    deps   = Deps.pip("mkdocs", "python-markdown-math"),
    repo = "github.com/abalkin/JuQ.jl.git",
    julia  = "0.6",
    osname = "osx"
)
