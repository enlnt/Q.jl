using Documenter, JuQ

makedocs()

deploydocs(
    deps   = Deps.pip("mkdocs", "python-markdown-math"),
    repo = "github.com/abalkin/JuQ.jl.git",
    julia  = "0.6",
    osname = "osx"
)
