using Documenter
using NeuralCompliance

DocMeta.setdocmeta!(NeuralCompliance, :DocTestSetup, :(using NeuralCompliance); recursive = true)

# Mirror the root CHANGELOG.md into docs/src so it's included in the
# rendered documentation site, not just visible on GitHub. Regenerated
# on every build, so CHANGELOG.md remains the single source of truth.
let
    src = joinpath(@__DIR__, "..", "CHANGELOG.md")
    dst = joinpath(@__DIR__, "src", "changelog.md")
    cp(src, dst; force = true)
end

makedocs(;
    modules = [NeuralCompliance],
    authors = "NeuralCompliance Contributors",
    repo = "https://github.com/Ciprian-LocalPulse/NeuralCompliance.jl/blob/{commit}{path}#{line}",
    sitename = "NeuralCompliance.jl",
    format = Documenter.HTML(;
        prettyurls = get(ENV, "CI", "false") == "true",
        canonical = "https://Ciprian-LocalPulse.github.io/NeuralCompliance.jl",
        edit_link = "main",
        assets = String[],
    ),
    pages = [
        "Home" => "index.md",
        "User Guide" => "guide.md",
        "API Reference" => "api.md",
        "Changelog" => "changelog.md",
    ],
)

deploydocs(; repo = "github.com/Ciprian-LocalPulse/NeuralCompliance.jl", devbranch = "main")
