# User Guide

This guide walks through the three validation strategies
`NeuralCompliance.jl` provides, using a toy credit-scoring network as
a running example. The full runnable version lives in
[`examples/basic_compliance_check.jl`](https://github.com/neuralcompliance/NeuralCompliance.jl/blob/main/examples/basic_compliance_check.jl).

## 1. Defining a model

Models are expressed as a `Vector{DenseLayer}`, where each
[`DenseLayer`](@ref) is an affine map followed by an elementwise
activation:

```julia
using NeuralCompliance

W1 = [0.8 -1.2 0.3; -0.5 0.9 0.1; 0.4 -0.3 0.7; -0.2 0.6 -0.4]
b1 = [0.1, -0.2, 0.05, 0.0]
W2 = reshape([1.1, -0.8, 0.5, -0.3], 1, 4)
b2 = [-0.2]

layers = [
    DenseLayer(W1, b1, relu),
    DenseLayer(W2, b2, sigmoid_bound),
]
```

Supported built-in activations: [`relu`](@ref), [`sigmoid_bound`](@ref),
[`tanh_bound`](@ref), and `identity`. Because these are sound
interval-valued functions, arbitrary custom activations can be
supported by providing your own `Interval -> Interval` function.

## 2. Certifying output bounds

Given an input region `[input_lo, input_hi]` (elementwise), propagate
it through the network:

```julia
output_intervals = certify_output_bounds(layers, [-2.0, -2.0, -2.0], [2.0, 2.0, 2.0])
```

The result is a `Vector{Interval}` — one certified interval per output
coordinate — guaranteed to contain the true output for *every* input
inside the box, not merely the corners or sampled interior points.

## 3. Declaring constraints

Constraints are declarative and separated from the checking logic:

```julia
constraints = AbstractConstraint[
    BoundConstraint("default_probability_in_unit_interval", 0.0, 1.0; risk_level=CRITICAL),
]
```

Three constraint families are provided out of the box:

- [`BoundConstraint`](@ref): output must stay within `[lower, upper]`.
- [`LipschitzConstraint`](@ref): local sensitivity must not exceed a
  maximum constant.
- [`MonotonicityConstraint`](@ref): output must be monotonic in a
  given input coordinate (e.g. default probability must never
  *decrease* as debt-to-income increases).

## 4. Running the audit

[`run_compliance_audit`](@ref) ties certification and constraint
checking together and returns a fingerprinted [`AuditReport`](@ref):

```julia
report = run_compliance_audit("credit_risk_v1", layers, input_lo, input_hi, constraints)
println(to_markdown(report))
```

## 5. Black-box stress testing

When only `f(x) -> y` is available (no architecture, no weights), use
Monte Carlo stress testing instead:

```julia
report = adversarial_stress_test(forward_fn, x0, 0.5; n_samples=2000, tolerance=0.4)
report.robust  # true/false
```

[`estimate_lipschitz`](@ref) uses the same machinery to produce a
lower-bound estimate of the local Lipschitz constant, useful as
evidence for a [`LipschitzConstraint`](@ref) when no closed-form bound
propagation rule is available.

## 6. Monotonicity sweeps

For [`MonotonicityConstraint`](@ref), sweep a single input coordinate
while holding the others fixed, and check the resulting output
sequence:

```julia
xs = collect(-2.0:0.1:2.0)
ys = [forward_fn([x, 0.0, 0.0]) for x in xs]

c = MonotonicityConstraint("dti_monotonic", 1, :increasing)
result = check_constraint(c, xs, ys)
```

## 7. Persisting audit trails

```julia
write_report(report, "audit_output/credit_risk_v1.md"; format=:markdown)
write_report(report, "audit_output/credit_risk_v1.json"; format=:json)
```

Every report carries a SHA-256 [`model_fingerprint`](@ref) of the
model artifact, so a report can always be tied back to an exact model
version during a later regulatory review.
