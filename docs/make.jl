using Documenter
using NeuralCompliance

DocMeta.setdocmeta!(NeuralCompliance, :DocTestSetup, :(using NeuralCompliance); recursive = true)

makedocs(;
    modules = [NeuralCompliance],
    authors = "NeuralCompliance Contributors",
    repo = "https://github.com/neuralcompliance/NeuralCompliance.jl/blob/{commit}{path}#{line}",
    sitename = "NeuralCompliance.jl",
    format = Documenter.HTML(;
        prettyurls = get(ENV, "CI", "false") == "true",
        canonical = "https://neuralcompliance.github.io/NeuralCompliance.jl",
        edit_link = "main",
        assets = String[],
    ),
    pages = ["Home" => "index.md", "User Guide" => "guide.md", "API Reference" => "api.md"],
)

deploydocs(; repo = "github.com/neuralcompliance/NeuralCompliance.jl", devbranch = "main")
