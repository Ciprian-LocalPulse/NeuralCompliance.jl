"""
Empirical robustness and stress testing.

Where [`interval_bounds.jl`](@ref) gives sound, worst-case guarantees
for a fixed model architecture, this module provides *model-agnostic*
Monte Carlo stress testing: it treats the model as an opaque function
`f(x) -> y` and probes its behavior under perturbation, without
requiring access to weights or gradients. This is the appropriate
tool when auditing third-party or black-box models, which is common
in vendor-risk assessments in regulated environments.
"""

"""
    StressTestReport

Summary statistics of a Monte Carlo adversarial stress test.
"""
struct StressTestReport
    n_samples::Int
    epsilon::Float64
    max_output_deviation::Float64
    mean_output_deviation::Float64
    empirical_lipschitz::Float64
    worst_case_input::Vector{Float64}
    robust::Bool
end

"""
    adversarial_stress_test(f, x0, epsilon; n_samples=1000, norm=:linf, rng=Random.default_rng(),
                             tolerance=Inf) -> StressTestReport

Probes `f` in an `epsilon`-ball around `x0` using random sampling and
reports how much the (scalar or vector) output can move.

# Arguments
- `f`: a function `f(x::Vector{Float64}) -> Union{Real, Vector{<:Real}}`.
- `x0`: nominal input point (`Vector{Float64}`).
- `epsilon`: perturbation radius.
- `n_samples`: number of Monte Carlo perturbations to draw.
- `norm`: `:linf` (box perturbation) or `:l2` (ball perturbation).
- `tolerance`: if the maximum observed output deviation exceeds this
  value, the report is marked `robust = false`. Defaults to `Inf`
  (report statistics only, no pass/fail judgement).

This is a randomized, *unsound* procedure: it can miss worst-case
points that a targeted (e.g. gradient-based) adversary would find. It
is intended as a fast, dependency-free triage tool, complementary to
-- not a replacement for -- the certified bounds in
[`propagate_bounds`](@ref).
"""
function adversarial_stress_test(f, x0::AbstractVector{<:Real}, epsilon::Real;
                                  n_samples::Int=1000, norm::Symbol=:linf,
                                  rng::AbstractRNG=Random.default_rng(),
                                  tolerance::Real=Inf)
    n_samples > 0 || throw(ArgumentError("n_samples must be positive"))
    epsilon >= 0 || throw(ArgumentError("epsilon must be non-negative"))
    d = length(x0)

    y0 = f(collect(Float64, x0))
    baseline_norm = _output_norm(y0)

    max_dev = 0.0
    sum_dev = 0.0
    max_lip = 0.0
    worst_x = collect(Float64, x0)

    for _ in 1:n_samples
        delta = _sample_perturbation(rng, d, epsilon, norm)
        x = collect(Float64, x0) .+ delta
        y = f(x)
        dev = _output_distance(y, y0)
        sum_dev += dev
        step_size = max(norm_of(delta), eps())
        lip = dev / step_size
        if dev > max_dev
            max_dev = dev
            worst_x = x
        end
        max_lip = max(max_lip, lip)
    end

    mean_dev = sum_dev / n_samples
    robust = max_dev <= tolerance

    StressTestReport(n_samples, Float64(epsilon), max_dev, mean_dev, max_lip, worst_x, robust)
end

"""
    estimate_lipschitz(f, x0, epsilon; n_samples=500, rng=Random.default_rng()) -> Float64

Estimates a local Lipschitz constant of `f` around `x0` via finite
differences over randomly sampled perturbation directions:

    L̂ = max_i ||f(x0 + δᵢ) - f(x0)|| / ||δᵢ||

This is a *lower bound* on the true local Lipschitz constant (a random
search cannot overestimate the true supremum), so it should be treated
as a diagnostic signal, not a certified upper bound. For certified
bounds use interval-based propagation where the architecture is known.
"""
function estimate_lipschitz(f, x0::AbstractVector{<:Real}, epsilon::Real;
                             n_samples::Int=500, rng::AbstractRNG=Random.default_rng())
    report = adversarial_stress_test(f, x0, epsilon; n_samples=n_samples, rng=rng)
    return report.empirical_lipschitz
end

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

function _sample_perturbation(rng::AbstractRNG, d::Int, epsilon::Real, norm::Symbol)
    if norm === :linf
        return (rand(rng, d) .* 2 .- 1) .* epsilon
    elseif norm === :l2
        v = randn(rng, d)
        v ./= max(norm_of(v), eps())
        r = epsilon * rand(rng)^(1 / d)  # uniform sampling within a ball
        return v .* r
    else
        throw(ArgumentError("norm must be :linf or :l2"))
    end
end

norm_of(v::AbstractVector{<:Real}) = sqrt(sum(abs2, v))

_output_norm(y::Real) = abs(y)
_output_norm(y::AbstractVector{<:Real}) = norm_of(y)

_output_distance(y::Real, y0::Real) = abs(y - y0)
_output_distance(y::AbstractVector{<:Real}, y0::AbstractVector{<:Real}) = norm_of(y .- y0)
