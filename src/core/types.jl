"""
Core type hierarchy for NeuralCompliance.jl.

This file defines the abstract and concrete types that represent
constraints, risk classifications, and compliance results within the
Zero-Trust Neural Compliance Framework. All validation subsystems
(interval bound propagation, robustness testing, audit logging)
operate over these shared types.
"""

# ---------------------------------------------------------------------------
# Risk classification
# ---------------------------------------------------------------------------

"""
    RiskLevel

Ordinal classification of the severity of a compliance violation,
loosely modeled on operational risk tiers used in regulated financial
environments (e.g. Basel-style risk buckets).
"""
@enum RiskLevel begin
    LOW
    MEDIUM
    HIGH
    CRITICAL
end

Base.string(r::RiskLevel) = string(Symbol(r))

# Julia's @enum does not define ordering by default; RiskLevel is
# ordinal (LOW < MEDIUM < HIGH < CRITICAL), so we opt in explicitly.
# This enables `maximum`/`minimum`/`sort` over RiskLevel collections,
# used e.g. by `highest_failing_risk`.
Base.isless(a::RiskLevel, b::RiskLevel) = Int32(a) < Int32(b)

# ---------------------------------------------------------------------------
# Constraints
# ---------------------------------------------------------------------------

"""
    AbstractConstraint

Supertype for all mathematical constraints that a model's behavior can
be checked against. Concrete subtypes must be usable with
[`check_constraint`](@ref).
"""
abstract type AbstractConstraint end

"""
    BoundConstraint{T<:Real} <: AbstractConstraint

Requires that every component of a model's output lies within
`[lower, upper]`. Typically used to certify, e.g., that a credit-risk
score or a probability output can never leave a mandated range.
"""
struct BoundConstraint{T <: Real} <: AbstractConstraint
    name::String
    lower::T
    upper::T
    risk_level::RiskLevel

    function BoundConstraint(
        name::String, lower::T, upper::T; risk_level::RiskLevel = HIGH
    ) where {T <: Real}
        lower <= upper || throw(ArgumentError("lower bound must be <= upper bound"))
        new{T}(name, lower, upper, risk_level)
    end
end

"""
    LipschitzConstraint <: AbstractConstraint

Requires that the estimated local Lipschitz constant of the model over
a region not exceed `max_constant`. A tight Lipschitz bound is a proxy
for output sensitivity to small input perturbations, which is directly
relevant to adversarial robustness and to "explainability under
perturbation" requirements common in regulated ML deployments.
"""
struct LipschitzConstraint <: AbstractConstraint
    name::String
    max_constant::Float64
    risk_level::RiskLevel

    function LipschitzConstraint(
        name::String, max_constant::Float64; risk_level::RiskLevel = MEDIUM
    )
        max_constant > 0 || throw(ArgumentError("max_constant must be positive"))
        new(name, max_constant, risk_level)
    end
end

"""
    MonotonicityConstraint <: AbstractConstraint

Requires that the model's output be monotonic (increasing or
decreasing) with respect to a given input coordinate. Common in
underwriting and pricing models where regulators require, e.g., that
predicted default probability never *decreases* as debt-to-income
increases.
"""
struct MonotonicityConstraint <: AbstractConstraint
    name::String
    input_index::Int
    direction::Symbol   # :increasing or :decreasing
    risk_level::RiskLevel

    function MonotonicityConstraint(
        name::String, input_index::Int, direction::Symbol; risk_level::RiskLevel = HIGH
    )
        direction in (:increasing, :decreasing) ||
            throw(ArgumentError("direction must be :increasing or :decreasing"))
        input_index > 0 || throw(ArgumentError("input_index must be positive"))
        new(name, input_index, direction, risk_level)
    end
end

# ---------------------------------------------------------------------------
# Results
# ---------------------------------------------------------------------------

"""
    ComplianceResult

Outcome of checking a single [`AbstractConstraint`](@ref) against a
model. Immutable record intended to be serialized into audit trails.
"""
struct ComplianceResult
    constraint_name::String
    passed::Bool
    risk_level::RiskLevel
    details::Dict{Symbol, Any}
    timestamp::DateTime
end

function ComplianceResult(
    name::AbstractString,
    passed::Bool,
    risk_level::RiskLevel,
    details::Dict{Symbol, Any} = Dict{Symbol, Any}(),
)
    ComplianceResult(String(name), passed, risk_level, details, now())
end
