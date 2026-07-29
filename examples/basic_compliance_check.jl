#!/usr/bin/env julia
#
# basic_compliance_check.jl
#
# End-to-end demonstration of NeuralCompliance.jl on a toy credit-risk
# scoring network: 3 inputs (income_ratio, debt_ratio, credit_history)
# -> 4-unit ReLU hidden layer -> 1 sigmoid output (default probability).
#
# Run with:  julia --project=. examples/basic_compliance_check.jl

using NeuralCompliance

# ---------------------------------------------------------------------------
# 1. Define the model as an explicit weight/bias stack.
#    (In practice these would be exported from a trained model, e.g. via
#    Flux.jl, and converted to plain Float64 matrices for this framework.)
# ---------------------------------------------------------------------------

W1 = [ 0.8  -1.2   0.3;
      -0.5   0.9   0.1;
       0.4  -0.3   0.7;
      -0.2   0.6  -0.4]
b1 = [0.1, -0.2, 0.05, 0.0]

W2 = reshape([1.1, -0.8, 0.5, -0.3], 1, 4)
b2 = [-0.2]

layers = [
    DenseLayer(W1, b1, relu),
    DenseLayer(W2, b2, sigmoid_bound),
]

# ---------------------------------------------------------------------------
# 2. Declare the compliance constraints a regulator (or internal model
#    risk management team) requires this model to satisfy.
# ---------------------------------------------------------------------------

constraints = AbstractConstraint[
    BoundConstraint("default_probability_in_unit_interval", 0.0, 1.0; risk_level=CRITICAL),
]

# ---------------------------------------------------------------------------
# 3. Certify the model over an input region using sound interval bound
#    propagation, and produce a fingerprinted audit report.
# ---------------------------------------------------------------------------

input_lo = [-2.0, -2.0, -2.0]   # normalized feature ranges
input_hi = [ 2.0,  2.0,  2.0]

report = run_compliance_audit("credit_risk_v1", layers, input_lo, input_hi, constraints)

println(to_markdown(report))

# ---------------------------------------------------------------------------
# 4. Complement the certified check with black-box adversarial stress
#    testing, in case the model were only available as f(x) -> y.
# ---------------------------------------------------------------------------

function forward(x::Vector{Float64})
    h = max.(W1 * x .+ b1, 0.0)
    return (1 ./ (1 .+ exp.(-(W2 * h .+ b2))))[1]
end

x0 = [0.0, 0.0, 0.0]
stress_report = adversarial_stress_test(forward, x0, 0.5; n_samples=2000, tolerance=0.4)

println()
println("Adversarial stress test around x0 = $x0, epsilon = 0.5")
println("  max output deviation:  $(round(stress_report.max_output_deviation, digits=4))")
println("  mean output deviation: $(round(stress_report.mean_output_deviation, digits=4))")
println("  empirical Lipschitz:   $(round(stress_report.empirical_lipschitz, digits=4))")
println("  robust (<=0.4 tol):    $(stress_report.robust)")

# ---------------------------------------------------------------------------
# 5. Persist the audit trail.
# ---------------------------------------------------------------------------

mkpath("audit_output")
write_report(report, joinpath("audit_output", "credit_risk_v1_audit.md"); format=:markdown)
write_report(report, joinpath("audit_output", "credit_risk_v1_audit.json"); format=:json)

println()
println("Audit trail written to ./audit_output/")
