"""
    NeuralCompliance

A Zero-Trust Neural Systems Validation and Compliance Framework for
Julia.

`NeuralCompliance.jl` provides a dependency-light, pure-Julia
mathematical compliance layer for auditing neural network (and more
generally, arbitrary numerical function) behavior against explicit,
inspectable constraints -- the kind of guarantees demanded when
deploying learned models in regulated environments such as banking,
insurance, and other financial services.

Three complementary validation strategies are provided:

1. **Certified bounds** ([`propagate_bounds`](@ref)) -- sound interval
   bound propagation through dense/ReLU-style architectures, giving
   worst-case guarantees over an entire input region, not just sampled
   points.
2. **Empirical stress testing** ([`adversarial_stress_test`](@ref)) --
   model-agnostic Monte Carlo perturbation analysis for black-box
   models.
3. **Audit trails** ([`generate_report`](@ref), [`to_markdown`](@ref))
   -- durable, fingerprinted compliance reports suitable for model-risk
   management documentation.

No dependency on Python or any machine learning framework is required;
`NeuralCompliance.jl` treats models as either explicit weight/bias
stacks ([`DenseLayer`](@ref)) or arbitrary Julia functions.
"""
module NeuralCompliance

using Dates
using LinearAlgebra
using Printf
using Random
using SHA
using Statistics

# ---------------------------------------------------------------------------
# Includes (order matters: types before code that dispatches on them)
# ---------------------------------------------------------------------------

include("core/types.jl")
include("validation/interval_bounds.jl")
include("core/constraints.jl")
include("validation/robustness.jl")
include("validation/audit_logger.jl")
include("utils/metrics.jl")

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

export
    # core types
    RiskLevel,
    LOW,
    MEDIUM,
    HIGH,
    CRITICAL,
    AbstractConstraint,
    BoundConstraint,
    LipschitzConstraint,
    MonotonicityConstraint,
    ComplianceResult,
    # interval bounds
    Interval,
    width,
    midpoint,
    relu,
    sigmoid_bound,
    tanh_bound,
    DenseLayer,
    propagate_bounds,
    affine_propagate,
    certify_output_bounds,
    # constraint checking
    check_constraint,
    # robustness
    StressTestReport,
    adversarial_stress_test,
    estimate_lipschitz,
    # audit
    AuditReport,
    generate_report,
    to_markdown,
    to_json,
    write_report,
    model_fingerprint,
    overall_passed,
    highest_failing_risk,
    # metrics
    max_abs_deviation,
    mean_absolute_error,
    root_mean_square,
    interval_tightness,
    risk_score,
    # orchestration
    run_compliance_audit

# ---------------------------------------------------------------------------
# High-level orchestration
# ---------------------------------------------------------------------------

"""
    run_compliance_audit(model_name, layers::Vector{<:DenseLayer},
                          input_lo, input_hi, constraints::Vector{<:AbstractConstraint};
                          model_data=layers) -> AuditReport

End-to-end convenience entry point for the certified-bounds workflow:
propagates `[input_lo, input_hi]` through `layers`, checks every
`BoundConstraint` in `constraints` against the certified output
interval(s), and returns a fingerprinted [`AuditReport`](@ref).

Non-`BoundConstraint` entries in `constraints` are skipped with a
`@warn`, since they require different evidence (see
[`adversarial_stress_test`](@ref) and the `MonotonicityConstraint`
sweep workflow in the documentation).
"""
function run_compliance_audit(
    model_name::AbstractString,
    layers::Vector{<:DenseLayer},
    input_lo::AbstractVector{<:Real},
    input_hi::AbstractVector{<:Real},
    constraints::Vector{<:AbstractConstraint};
    model_data = layers,
)
    output_intervals = certify_output_bounds(layers, input_lo, input_hi)

    results = ComplianceResult[]
    for c in constraints
        if c isa BoundConstraint
            # Apply the bound constraint to every certified output coordinate.
            for (idx, out_i) in enumerate(output_intervals)
                res = check_constraint(c, out_i)
                res = ComplianceResult(
                    "$(res.constraint_name)[output=$idx]",
                    res.passed,
                    res.risk_level,
                    res.details,
                    res.timestamp,
                )
                push!(results, res)
            end
        else
            @warn "Skipping constraint requiring different evidence" constraint = c
        end
    end

    return generate_report(model_name, model_data, results)
end

end # module NeuralCompliance
