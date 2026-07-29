using Aqua
using NeuralCompliance
using Test

@testset "Aqua.jl quality checks" begin
    # Run the full Aqua suite except `deps_compat`, which is checked
    # separately below with a Julia-version-specific exclusion (see note).
    Aqua.test_all(
        NeuralCompliance;
        ambiguities = true,
        unbound_args = true,
        undefined_exports = true,
        project_extras = true,
        stale_deps = true,
        deps_compat = false,
        piracies = true,
        persistent_tasks = false,
    )

    # `deps_compat` is run on its own so that `NeuralCompliance` itself
    # can be excluded from the "declared but not directly loaded"
    # heuristic without disabling the check for the actual stdlib deps
    # (Dates, LinearAlgebra, Printf, Random, SHA, Statistics).
    Aqua.test_deps_compat(NeuralCompliance; check_extras = false)
end
