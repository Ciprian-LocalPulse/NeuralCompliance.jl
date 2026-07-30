---
title: 'NeuralCompliance.jl: A Zero-Trust Framework for Certified Neural Network Compliance Auditing in Julia'
tags:
  - Julia
  - neural networks
  - formal verification
  - interval arithmetic
  - model risk management
  - AI compliance
  - adversarial robustness
authors:
  - name: Ciprian Stefan Plesca
    orcid: 0000-0000-0000-0000
    affiliation: 1
affiliations:
  - name: Independent Researcher
    index: 1
date: 29 July 2026
bibliography: paper.bib
---

# Summary

`NeuralCompliance.jl` is a Julia package for auditing whether a neural
network's outputs satisfy declared constraints — bound constraints,
Lipschitz-continuity constraints, and monotonicity constraints — over
an entire region of input space, rather than over a finite set of
sampled points. It provides two distinct verification pathways:
a *certified* pathway based on interval bound propagation (IBP)
[@gowal2018ibp], which yields a mathematically sound worst-case
guarantee for dense, ReLU-sequential networks; and an *empirical*
pathway based on Monte Carlo sampling and finite-difference estimation,
which is model-agnostic and applicable to arbitrary black-box
`f(x) -> y` functions but carries a correspondingly weaker guarantee.
Every result the package produces is tagged with the method that
produced it, so that a certified guarantee is never silently conflated
with an empirical one. The package also produces SHA-256-fingerprinted,
Markdown- or JSON-formatted audit reports intended for model-risk-management
(MRM) documentation packages, and depends on no machine-learning
framework or Python interop layer — its only non-standard-library
dependency is `SHA.jl`.

# Statement of Need

Regulated deployments of machine learning models — credit
underwriting, insurance pricing, algorithmic trading risk controls,
clinical decision support — increasingly require model risk management
functions and external auditors to produce compliance evidence that
goes beyond a held-out accuracy or AUC figure [@nist_ai_rmf;
@eu_ai_act]. A held-out test-set metric is a statement about a sample;
it says nothing about the model's behavior on the (generally infinite)
set of inputs that were never tested, including inputs an adversary or
an unusual operating condition might produce. Formal verification
methods for neural networks — including interval bound propagation,
abstract interpretation, and SMT-based approaches [@katz2017reluplex;
@singh2019abstract] — exist to close exactly this gap, but the
majority of accessible open-source tooling for this problem lives in
the Python/PyTorch ecosystem and is not designed with a
compliance-documentation workflow (fingerprinted, versioned,
human-and-machine-readable audit trails) as a first-class output.
`NeuralCompliance.jl` addresses this gap for the Julia ecosystem, where
native multiple dispatch makes it straightforward to propagate a
custom `Interval` numeric type through ordinary dense-layer linear
algebra at close to native `Float64` performance, without a
hand-written C extension or an external interval-arithmetic
dependency.

The package is explicitly designed around a "zero-trust" principle: no
model is assumed to behave acceptably outside a region that has either
been certified via sound bound propagation or explicitly, transparently
sampled. This distinction — between a proof and an estimate — is
treated as the central design constraint of the API rather than as
documentation to be read separately from it: every `ComplianceResult`
carries a `:method` field identifying which of the two pathways
produced it.

# Certified and Empirical Verification Pathways

For a dense, ReLU-sequential network expressed as a
`Vector{DenseLayer}`, `NeuralCompliance.jl` propagates an input
`Interval` — an axis-aligned box in input space — layer by layer,
tracking the coordinate-wise lower and upper bounds achievable by each
subsequent activation. A `BoundConstraint` checked against the
resulting output interval is a sound guarantee: if it passes, no point
in the input region can produce an output violating the constraint,
regardless of whether that specific point was ever evaluated directly.

For constraints or model classes outside this certified path — an
estimated Lipschitz constant via sampled finite differences, a
monotonicity sweep along an input coordinate, or any black-box model
for which no closed-form propagation rule is implemented — the package
falls back to empirical, sample-based checking. These checks are
clearly weaker: they certify only the sampled points, not the region
as a whole. The package's design decision is to expose this weaker
guarantee through the same API surface as the sound one, differentiated
only by an explicit `:method` tag, rather than hiding the distinction
behind a uniform "compliant / non-compliant" verdict.

# Current Limitations

As documented in `COMPLIANCE_METHODOLOGY.md` and `THREAT_MODEL.md`
in the package repository, the certified pathway currently covers only
dense, ReLU-sequential architectures — convolutional and
skip-connection topologies are not yet supported. The interval
arithmetic implementation does not yet apply directional (outward)
floating-point rounding, so the soundness guarantee is currently a
mathematical one rather than a bit-exact numerical one at bound
boundaries. The Lipschitz-constant estimator produces an empirical
lower bound, not a certified upper bound, and should not be treated as
an adversarial-robustness certificate. These limitations are tracked
as prioritized items in the project roadmap.

# Acknowledgements

The author thanks early users and reviewers of the package's wiki
documentation for feedback that shaped `COMPLIANCE_METHODOLOGY.md` and
`THREAT_MODEL.md`.

# References
