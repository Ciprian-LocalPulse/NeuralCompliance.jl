"""
Constraint-checking dispatch table.

Each concrete `AbstractConstraint` subtype gets a `check_constraint`
method. The function signatures deliberately accept heterogeneous
evidence (an `Interval`, a raw output vector, an estimated Lipschitz
constant, ...) because different constraints require fundamentally
different evidence to certify.
"""

"""
    check_constraint(c::BoundConstraint, output::Interval) -> ComplianceResult

Certifies a [`BoundConstraint`](@ref) using a *sound* output interval
(typically produced by [`propagate_bounds`](@ref)). Because interval
bound propagation is conservative, passing this check is a guarantee
that holds for *every* input in the certified input region, not just
for sampled points.
"""
function check_constraint(c::BoundConstraint, output::Interval)
    passed = output.lo >= c.lower && output.hi <= c.upper
    details = Dict{Symbol, Any}(
        :certified_lower => output.lo,
        :certified_upper => output.hi,
        :required_lower => c.lower,
        :required_upper => c.upper,
        :method => :interval_bound_propagation,
    )
    ComplianceResult(c.name, passed, c.risk_level, details)
end

"""
    check_constraint(c::BoundConstraint, outputs::AbstractVector{<:Real}) -> ComplianceResult

Empirical (sample-based) variant. Weaker guarantee than the interval
form -- only certifies the sampled points -- but useful for quick
smoke checks and for constraints where no closed-form bound
propagation rule exists.
"""
function check_constraint(c::BoundConstraint, outputs::AbstractVector{<:Real})
    lo, hi = extrema(outputs)
    passed = lo >= c.lower && hi <= c.upper
    n_violations = count(x -> x < c.lower || x > c.upper, outputs)
    details = Dict{Symbol, Any}(
        :observed_lower => lo,
        :observed_upper => hi,
        :required_lower => c.lower,
        :required_upper => c.upper,
        :n_samples => length(outputs),
        :n_violations => n_violations,
        :method => :empirical_sampling,
    )
    ComplianceResult(c.name, passed, c.risk_level, details)
end

"""
    check_constraint(c::LipschitzConstraint, estimated_constant::Real) -> ComplianceResult

Certifies a [`LipschitzConstraint`](@ref) against an estimate produced
by [`estimate_lipschitz`](@ref).
"""
function check_constraint(c::LipschitzConstraint, estimated_constant::Real)
    passed = estimated_constant <= c.max_constant
    details = Dict{Symbol, Any}(
        :estimated_constant => estimated_constant,
        :max_allowed => c.max_constant,
        :margin => c.max_constant - estimated_constant,
    )
    ComplianceResult(c.name, passed, c.risk_level, details)
end

"""
    check_constraint(c::MonotonicityConstraint, xs::AbstractVector, ys::AbstractVector{<:Real}) -> ComplianceResult

Certifies monotonicity along a 1-D sweep of the input coordinate
`c.input_index`, where `xs` are the swept coordinate values (sorted
ascending) and `ys` are the corresponding scalar model outputs.
"""
function check_constraint(c::MonotonicityConstraint, xs::AbstractVector, ys::AbstractVector{<:Real})
    issorted(xs) || throw(ArgumentError("xs must be sorted ascending for a monotonicity sweep"))
    diffs = diff(ys)
    passed = if c.direction === :increasing
        all(d -> d >= -eps(Float64) * 10, diffs)
    else
        all(d -> d <= eps(Float64) * 10, diffs)
    end
    n_violations = if c.direction === :increasing
        count(d -> d < -eps(Float64) * 10, diffs)
    else
        count(d -> d > eps(Float64) * 10, diffs)
    end
    details = Dict{Symbol, Any}(
        :input_index => c.input_index,
        :direction => c.direction,
        :n_points => length(xs),
        :n_violations => n_violations,
        :max_step => length(diffs) > 0 ? maximum(abs.(diffs)) : 0.0,
    )
    ComplianceResult(c.name, passed, c.risk_level, details)
end
