#!/usr/bin/env julia
#
# bench_interval_bounds.jl
#
# Performance benchmarks for sound interval bound propagation
# (`propagate_bounds` / `affine_propagate`), the core primitive used to
# certify `BoundConstraint`s (see WHITEPAPER.md §4). Interval arithmetic
# does roughly 2x the flops of plain Float64 forward passes (center +
# radius), so this suite tracks that overhead across model sizes and
# guards against regressions as the implementation evolves.
#
# Run with:
#   julia --project=benchmark benchmark/bench_interval_bounds.jl
#
# For a quick pass suitable for CI (fewer samples, less precise):
#   julia --project=benchmark -e 'include("benchmark/bench_interval_bounds.jl")' --ci

using BenchmarkTools
using NeuralCompliance
using Random

Random.seed!(1234)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

"""
    random_mlp(dims; seed=1234) -> Vector{DenseLayer}

Builds a random dense ReLU MLP (final layer left as `identity`) with
layer widths given by `dims`, e.g. `random_mlp([10, 64, 64, 1])`.
"""
function random_mlp(dims::Vector{Int})
    layers = DenseLayer[]
    for i in 1:(length(dims) - 1)
        W = 0.5 .* randn(dims[i + 1], dims[i])
        b = 0.1 .* randn(dims[i + 1])
        act = i == length(dims) - 1 ? identity : relu
        push!(layers, DenseLayer(W, b, act))
    end
    return layers
end

function unit_box_input(n::Int)
    return Interval.(fill(-1.0, n), fill(1.0, n))
end

# ---------------------------------------------------------------------------
# Model sizes to benchmark.
#
# "small"  : a toy tabular model, similar to examples/basic_compliance_check.jl
# "medium" : a moderately wide MLP, representative of tabular risk models
# "large"  : a deep/wide MLP, to observe how propagation cost scales
# ---------------------------------------------------------------------------

const MODEL_SHAPES = Dict(
    "small" => [8, 16, 1],
    "medium" => [64, 128, 128, 8],
    "large" => [256, 512, 512, 512, 16],
)

const SUITE = BenchmarkGroup()
SUITE["propagate_bounds"] = BenchmarkGroup()
SUITE["affine_propagate"] = BenchmarkGroup()

for (name, dims) in MODEL_SHAPES
    layers = random_mlp(dims)
    input = unit_box_input(dims[1])

    SUITE["propagate_bounds"][name] = @benchmarkable(
        propagate_bounds($layers, $input), samples = 200, seconds = 5
    )

    first_layer = layers[1]
    SUITE["affine_propagate"][name] = @benchmarkable(
        affine_propagate($(first_layer.weights), $(first_layer.bias), $input),
        samples = 200,
        seconds = 5,
    )
end

# ---------------------------------------------------------------------------
# Run, print, and (optionally) compare against a saved baseline.
#
# To capture a baseline after a change you believe improves performance:
#   results = run(SUITE)
#   BenchmarkTools.save("benchmark/baseline.json", results)
#
# To compare a new run against that baseline:
#   baseline = BenchmarkTools.load("benchmark/baseline.json")[1]
#   judge(median(run(SUITE)), median(baseline))
# ---------------------------------------------------------------------------

if abspath(PROGRAM_FILE) == @__FILE__ || "--ci" in ARGS
    println("Running NeuralCompliance.jl interval-bound-propagation benchmarks...")
    tune!(SUITE)
    results = run(SUITE; verbose = true)
    display(results)
    println()
end
