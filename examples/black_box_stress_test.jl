#!/usr/bin/env julia
#
# black_box_stress_test.jl
#
# End-to-end demonstration of NeuralCompliance.jl's *empirical*
# validation path (WHITEPAPER.md §6), for auditing a vendor-supplied
# model whose weights/architecture are NOT exposed to the auditor --
# only a callable `f(x) -> y`. This is the model-agnostic complement
# to examples/basic_compliance_check.jl, which requires the explicit
# DenseLayer stack needed for certified interval bound propagation.
#
# Scenario: a third-party fraud-scoring API returns a scalar risk score
# in [0, 1] for a transaction feature vector. The vendor will not
# disclose model internals, so the only available validation strategy
# is Monte Carlo adversarial stress testing plus a monotonicity sweep
# on the one input the compliance team has been told the model should
# never react "backwards" to (transaction amount).
#
# Run with:  julia --project=. examples/black_box_stress_test.jl

using NeuralCompliance
using Random

Random.seed!(2026)

# ---------------------------------------------------------------------------
# 1. Stand in for the vendor's undisclosed black-box model.
#
#    In a real audit this `vendor_fraud_score` function would instead
#    be an HTTP call to the vendor's scoring endpoint. NeuralCompliance
#    never needs to see inside it -- only call it.
# ---------------------------------------------------------------------------

function vendor_fraud_score(x::Vector{Float64})
    amount, hour_of_day, distance_from_home, velocity_24h = x
    z = 0.9 * tanh(amount / 500) + 0.4 * sin(hour_of_day / 24 * 2pi) +
        0.6 * tanh(distance_from_home / 100) + 0.5 * tanh(velocity_24h / 5)
    return 1 / (1 + exp(-z))
end

x0 = [120.0, 14.0, 8.0, 1.0]   # a typical, low-risk transaction

# ---------------------------------------------------------------------------
# 2. Empirical stress test: how much can the score move under a small,
#    realistic perturbation of the input (§6's Monte Carlo procedure)?
# ---------------------------------------------------------------------------

stress_report = adversarial_stress_test(
    vendor_fraud_score, x0, 0.15; n_samples = 5000, norm = :l2, tolerance = 0.25
)

println("Black-box adversarial stress test (vendor fraud-scoring model)")
println("  base point:            $x0")
println("  perturbation radius:   0.15 (L2 ball)")
println("  samples:               5000")
println("  max output deviation:  $(round(stress_report.max_output_deviation, digits=4))")
println("  mean output deviation: $(round(stress_report.mean_output_deviation, digits=4))")
println("  empirical Lipschitz:   $(round(stress_report.empirical_lipschitz, digits=4))")
println("  robust (<=0.25 tol):   $(stress_report.robust)")
println()
println("Reminder: this is an unsound, sampled estimate (WHITEPAPER.md §6) --")
println("it can miss a worst-case point a targeted adversary would find. It")
println("is reported as a diagnostic signal, never as a certified guarantee.")

# ---------------------------------------------------------------------------
# 3. Declare and check the compliance constraints available for a model
#    audited only empirically: a Lipschitz sensitivity budget, and a
#    monotonicity requirement swept along one input coordinate.
# ---------------------------------------------------------------------------

lipschitz_constraint = LipschitzConstraint(
    "fraud_score_local_sensitivity_budget", 1.5; risk_level = MEDIUM
)
lipschitz_result = check_constraint(lipschitz_constraint, stress_report.empirical_lipschitz)

# Monotonicity sweep: transaction velocity in the last 24h should never
# *decrease* the fraud score as it increases.
velocity_grid = collect(0.0:0.5:10.0)
scores_along_velocity =
    [vendor_fraud_score([x0[1], x0[2], x0[3], v]) for v in velocity_grid]

monotonicity_constraint = MonotonicityConstraint(
    "fraud_score_monotone_in_velocity_24h", 4, :increasing; risk_level = HIGH
)
monotonicity_result =
    check_constraint(monotonicity_constraint, velocity_grid, scores_along_velocity)

# ---------------------------------------------------------------------------
# 4. Assemble and persist the audit trail, exactly as with the
#    certified-bounds workflow -- the report format does not
#    distinguish how a result was obtained, only whether it passed.
# ---------------------------------------------------------------------------

results = ComplianceResult[lipschitz_result, monotonicity_result]
report = generate_report("vendor_fraud_scorer_v3", (x0, velocity_grid), results)

println()
println("Overall compliant: $(overall_passed(report))")

mkpath("audit_output")
write_report(report, joinpath("audit_output", "vendor_fraud_scorer_v3_audit.md"); format = :markdown)
write_report(report, joinpath("audit_output", "vendor_fraud_scorer_v3_audit.json"); format = :json)

println("Audit trail written to ./audit_output/")
