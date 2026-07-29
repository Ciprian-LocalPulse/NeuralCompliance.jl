"""
Shared numerical metrics used across the validation subsystems.
"""

"""
    max_abs_deviation(a, b) -> Real

Maximum absolute elementwise deviation between two equal-length
vectors (or two scalars).
"""
max_abs_deviation(a::Real, b::Real) = abs(a - b)
max_abs_deviation(a::AbstractVector{<:Real}, b::AbstractVector{<:Real}) = maximum(abs.(a .- b))

"""
    mean_absolute_error(a, b) -> Real
"""
function mean_absolute_error(a::AbstractVector{<:Real}, b::AbstractVector{<:Real})
    length(a) == length(b) || throw(ArgumentError("vectors must have equal length"))
    return Statistics.mean(abs.(a .- b))
end

"""
    root_mean_square(v) -> Real
"""
root_mean_square(v::AbstractVector{<:Real}) = sqrt(Statistics.mean(abs2, v))

"""
    interval_tightness(i::Interval) -> Real

Returns `width(i)`, a simple proxy for how "tight" (informative) a
certified bound is. Wider certified intervals indicate either a large
input region or accumulated conservatism in bound propagation.
"""
interval_tightness(i::Interval) = width(i)

"""
    risk_score(results::Vector{ComplianceResult}) -> Float64

Aggregates a batch of compliance results into a single scalar risk
score in `[0, 1]`, weighting failures by risk level. `0.0` indicates a
fully compliant model; higher scores indicate more severe or more
numerous violations.
"""
function risk_score(results::Vector{ComplianceResult})
    isempty(results) && return 0.0
    weights = Dict(LOW => 0.25, MEDIUM => 0.5, HIGH => 0.75, CRITICAL => 1.0)
    total = sum(r.passed ? 0.0 : weights[r.risk_level] for r in results)
    return min(total / length(results), 1.0)
end
