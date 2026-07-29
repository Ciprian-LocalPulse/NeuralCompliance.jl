```@meta
CurrentModule = NeuralCompliance
```

```@docs
NeuralCompliance
```

# NeuralCompliance.jl

*A Zero-Trust Neural Systems Validation and Compliance Framework, in
pure Julia.*

`NeuralCompliance.jl` is a dependency-light mathematical compliance
layer for auditing the numerical behavior of neural networks (and,
more generally, arbitrary Julia functions) against explicit, formally
inspectable constraints. It was designed with regulated-industry
deployment in mind — banking, insurance, healthcare underwriting —
where "the model performed well on a test set" is not an acceptable
substitute for a certified, reproducible compliance argument.

## Why "Zero-Trust"?

The framework treats every model as untrusted by default:

- **No assumption of good behavior outside the training distribution.**
  [`propagate_bounds`](@ref) computes *sound* (worst-case) output
  bounds over an entire input region using interval arithmetic —
  not just at sampled points.
- **No implicit trust in vendor claims for black-box models.**
  [`adversarial_stress_test`](@ref) and [`estimate_lipschitz`](@ref)
  empirically probe opaque `f(x) -> y` models without requiring
  access to weights or gradients.
- **No untracked provenance.** Every [`AuditReport`](@ref) is
  fingerprinted with a SHA-256 digest of the model artifact it was
  generated from ([`model_fingerprint`](@ref)), so that a report can
  never be silently reattached to a different (possibly modified)
  model.

## Three pillars

| Pillar | Module | Guarantee |
|---|---|---|
| Certified bounds | `validation/interval_bounds.jl` | Sound, worst-case, over an entire input region |
| Empirical stress testing | `validation/robustness.jl` | Model-agnostic, Monte Carlo, works on black-box models |
| Audit trail | `validation/audit_logger.jl` | Fingerprinted, durable, Markdown/JSON export |

## Installation

```julia
using Pkg
Pkg.add(url="https://github.com/neuralcompliance/NeuralCompliance.jl")
```

## Quick example

```julia
using NeuralCompliance

layers = [
    DenseLayer(W1, b1, relu),
    DenseLayer(W2, b2, sigmoid_bound),
]

constraints = AbstractConstraint[
    BoundConstraint("output_probability", 0.0, 1.0; risk_level=CRITICAL),
]

report = run_compliance_audit("my_model", layers, input_lo, input_hi, constraints)
println(to_markdown(report))
```

See the [User Guide](guide.md) for a walkthrough and the
[API Reference](api.md) for full documentation of every exported
symbol.

## No Python dependency

`NeuralCompliance.jl` is implemented entirely in Julia's standard
library plus [SHA.jl](https://github.com/JuliaCrypto/SHA.jl) for
fingerprinting. It does not require PyCall, PythonCall, or any
Python-based ML framework, which keeps the dependency surface — and
therefore the audit surface — minimal.
