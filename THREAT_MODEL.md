# Threat Model

This document describes what `NeuralCompliance.jl` defends against,
what it assumes, and what is explicitly out of scope. It complements
[`COMPLIANCE_METHODOLOGY.md`](COMPLIANCE_METHODOLOGY.md) (which
explains what a *result* means) by describing what kind of *adversary
or failure mode* each part of the package is, and is not, designed to
withstand.

## 1. What "Zero-Trust" Means Here

The package's design principle — reflected in the README's "Zero-Trust
Neural Systems Validation" framing — is: **do not trust the model's
own outputs on any input you have not either certified via sound
interval propagation or explicitly sampled and logged.** A model that
scored well on a holdout set is not, by that fact alone, trusted by
this framework. Trust, in this codebase, is something a constraint
check has to earn for a specific claim over a specific input region.

## 2. In-Scope Threats

### 2.1 Adversarial or out-of-distribution inputs within a certified region

If a `BoundConstraint` is certified via `propagate_bounds` over an
`Interval` input region, the guarantee holds for **every** point in
that region, including adversarially chosen points, points far from
the training distribution, and points no human ever manually tested.
This is the primary threat this package is built to address: the gap
between "we tested some inputs" and "we can bound behavior over a
whole region."

### 2.2 Silent regression after retraining

Because certification is a statement about specific weights, not a
model architecture in the abstract, re-running the certification suite
after any weight update is the mechanism by which this package detects
a previously-compliant model silently becoming non-compliant (e.g.
after fine-tuning, quantization, or a training bug).

### 2.3 Undocumented or unaudited compliance claims

`src/validation/audit_logger.jl` exists specifically so that a
compliance claim is not just "the code returned `true`" but a
reproducible, timestamped, inspectable record of what was checked,
against what constraint, using what method.

## 3. Explicitly Out of Scope

Being direct about these matters more than listing what the package
does well.

- **Training-time attacks.** `NeuralCompliance.jl` validates a
  trained model's behavior. It does not detect data poisoning,
  backdoors inserted during training, or supply-chain compromise of
  the training pipeline itself.
- **Confidentiality / model extraction.** This package is not a
  defense against an attacker trying to steal or reverse-engineer a
  model via query access. It assumes the party running the
  certification has legitimate white-box access to the model.
- **Architectures outside the certified path.** As stated in
  `COMPLIANCE_METHODOLOGY.md` §4, only dense/ReLU-sequential networks
  get the sound IBP guarantee today. Any other architecture is,
  implicitly, only as trustworthy as the empirical checks run against
  it — see the threat in §4 below.
- **The Lipschitz estimator, as an adversarial defense.** Per
  `COMPLIANCE_METHODOLOGY.md` §2, `estimate_lipschitz` is an empirical
  lower bound. An adversary with query access could, in principle,
  find inputs where the true local Lipschitz constant is much higher
  than what sampling observed. Do not rely on a passing
  `LipschitzConstraint` check as an adversarial robustness certificate
  until the certified upper-bound estimator (tracked in `ROADMAP.md`)
  ships.
- **Numerical/floating-point soundness at bound boundaries.** As
  noted in `COMPLIANCE_METHODOLOGY.md` §3, directional rounding is not
  yet implemented. A sufficiently adversarial input sitting exactly at
  a certified boundary could, in principle, expose a floating-point
  rounding discrepancy the mathematical proof does not account for.
- **Compromise of the machine running the certification.** The
  package assumes the Julia process, its dependencies, and the
  environment it runs in are themselves trustworthy. It is not a
  runtime sandbox and does not defend against a compromised host
  falsifying its own outputs.

## 4. Failure Mode: Empirical Results Mistaken for Certified Ones

The single most consequential misuse of this package is treating an
`:empirical_sampling` result — from `BoundConstraint` on a sample
vector, `LipschitzConstraint`, or `MonotonicityConstraint` — as if it
carried the same guarantee as an `:interval_bound_propagation` result.
This is not a bug in the package; it is a documentation and API-design
risk, which is why the `:method` key exists on every
`ComplianceResult.details` (see `COMPLIANCE_METHODOLOGY.md` §1) and why
downstream consumers of this package should always branch on that key
before reporting a result upstream as a "certified" compliance claim.

## 5. Reporting

Vulnerabilities, soundness gaps, or scenarios not covered above that
you believe should be should be reported per the process in
[`SECURITY.md`](SECURITY.md).
