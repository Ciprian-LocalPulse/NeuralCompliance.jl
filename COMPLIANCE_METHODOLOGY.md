# Compliance Methodology

This document explains, precisely, what a `NeuralCompliance.jl`
certification result does and does not guarantee. It exists because
"the check passed" is meaningless without knowing what kind of check
it was — and because that distinction matters most exactly when
someone is relying on this package to satisfy a regulatory or
governance obligation.

This is the root-level counterpart to the longer methodology
discussion in the project wiki. It is kept here, in the repository
itself, because the wiki is **not** included in `git clone` and is
therefore invisible to anyone auditing the package offline, from a
vendored copy, or from the released tarball.

## 1. The Core Distinction: Certified vs. Empirical

Every `ComplianceResult` produced by `check_constraint` includes a
`details` dictionary. Where applicable, that dictionary carries an
explicit `:method` key, which is the single most important field to
read before trusting a result. There are exactly two values it can
take today:

| `:method` value | What it means | What it does NOT mean |
|---|---|---|
| `:interval_bound_propagation` | The bound was derived by propagating a *sound* interval through every layer of the network. If the constraint passes, it provably holds for **every point** in the certified input region — not just the points anyone happened to check. | It does not account for floating-point rounding at the hardware level (see §3). It does not extend past the input region you propagated. |
| `:empirical_sampling` | The bound was checked against a **finite set of sampled outputs** (or, for `estimate_lipschitz` and `MonotonicityConstraint`, a finite set of sampled points/sweeps). A pass means no violation was found among the samples taken. | It is **not** a guarantee for inputs that were not sampled. It is statistical confidence, not mathematical proof. |

If a `ComplianceResult`'s `details` dict has no `:method` key at all,
treat that as `:empirical_sampling` until the calling code is updated
to tag it explicitly (see `ROADMAP.md`).

## 2. What Each Public Entry Point Actually Certifies

- **`propagate_bounds` + `check_constraint(::BoundConstraint, ::Interval)`**
  — Sound. This is the only fully certified path in the package today.
  The result holds for the entire input region described by the
  `Interval` you propagated, not merely for sampled points within it.

- **`check_constraint(::BoundConstraint, ::AbstractVector{<:Real})`**
  — Empirical. Certifies only the samples given.

- **`estimate_lipschitz` + `check_constraint(::LipschitzConstraint, ...)`**
  — Empirical **lower bound**. This is the most important caveat in
  the entire package: `estimate_lipschitz` does not compute a
  certified upper bound on the Lipschitz constant. It estimates one
  from sampled finite differences. A model can have a true Lipschitz
  constant far higher than what was observed, if the sampling did not
  happen to probe the region where the function is steepest. Do not
  use a passing `LipschitzConstraint` check as a sound certification
  in a context where an adversary controls the input. A certified
  upper-bound estimator (e.g. via operator-norm bounds on weight
  matrices, layer-wise Lipschitz composition, or interval-based
  methods) is tracked as a P0 item in `ROADMAP.md`.

- **`check_constraint(::MonotonicityConstraint, ...)`** — Empirical.
  Certifies monotonicity only along the specific 1-D sweep of sampled
  points provided, not over the continuous input region.

- **`audit_logger` outputs** — A faithful record of what was checked
  and what the result was. The audit log inherits whatever
  soundness level the underlying check had; it does not upgrade an
  empirical result into a certified one.

## 3. What "Sound" Does Not Cover

Even the certified (`:interval_bound_propagation`) path is a
**mathematical** soundness guarantee, not a **numerical** one in the
strictest sense. Interval arithmetic implemented with standard
floating-point operations can, in principle, suffer from rounding
error at bound boundaries unless directional rounding (rounding
outward, away from the true value, at every operation) is used.
`NeuralCompliance.jl` does not currently implement directional
rounding for its `Interval` type. In practice this means:

- The mathematical logic of the certification is sound.
- The floating-point implementation of that logic has not been
  hardened against rounding-induced boundary violations.

Investigating directional rounding (and possible interoperability
with `IntervalArithmetic.jl`, which does implement it) is tracked as
a P0 item in `ROADMAP.md`. Until resolved, treat certifications near a
constraint boundary with additional caution.

## 4. Scope: What Kind of Networks This Covers

The certified (IBP) path currently supports `Vector{DenseLayer}` —
dense, ReLU-sequential architectures. It does not yet support
convolutions, skip connections, attention, or other non-sequential
topologies. If your model falls outside this class, any compliance
result you obtain either does not apply to it, or was necessarily
produced via the empirical path with all the caveats in §1–2 above.

## 5. Recommended Practice for Regulated Use

If you are using `NeuralCompliance.jl` to support a regulatory,
audit, or governance claim:

1. Confirm the `:method` on every `ComplianceResult` you rely on.
2. Treat `:empirical_sampling` results as evidence, not proof — report
   them as such to reviewers.
3. Do not use `LipschitzConstraint` results as an adversarial-robustness
   guarantee until a certified upper-bound estimator lands.
4. Keep the audit log (`src/validation/audit_logger.jl`) enabled and
   retained per your organization's record-keeping requirements — it
   is your evidence trail, not a substitute for the underlying method's
   soundness.
5. Re-run certifications after any model retraining, fine-tuning, or
   weight update. A certification is a statement about the weights
   that were checked, not about the model class in the abstract.

## 6. Reporting a Soundness Gap

If you find a case where a `:interval_bound_propagation` result passes
but the constraint is actually violated somewhere in the certified
region, this is the highest-severity class of bug this project can
have. Please report it via a GitHub issue using the "Bug report"
template, explicitly marked as a soundness bug, or see `SECURITY.md`
if you believe it has security implications.
