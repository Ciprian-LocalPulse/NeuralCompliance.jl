# Changelog

All notable changes to `NeuralCompliance.jl` are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- `.gitattributes` to enforce consistent LF line endings across the repo.
- `CHANGELOG.md` (this file).
- `SECURITY.md` with a vulnerability-disclosure process.
- Issue templates (bug report, feature request) and a pull request template
  under `.github/`.
- Cross-links between `README.md`, `ROADMAP.md`, and `WHITEPAPER.md`.

## [0.1.0] — 2026

### Added
- Initial release of `NeuralCompliance.jl`: a zero-trust neural systems
  validation and compliance framework, written in pure Julia.
- Sound interval bound propagation (IBP) for Dense/ReLU networks
  (`src/validation/interval_bounds.jl`).
- Constraint-checking layer supporting monotonicity, range, and
  fairness-style constraint families (`src/core/constraints.jl`).
- Monte Carlo black-box robustness/stress-testing pipeline
  (`src/validation/robustness.jl`).
- Fingerprinted, reproducible Markdown/JSON audit reports with SHA-based
  provenance (`src/validation/audit_logger.jl`).
- Core type system (`src/core/types.jl`) and metrics utilities
  (`src/utils/metrics.jl`).
- Test suite covering interval-arithmetic soundness properties, constraint
  dispatch, the stress-testing pipeline, and audit-report determinism.
- Documentation site scaffold (`docs/`), example script
  (`examples/basic_compliance_check.jl`), `CONTRIBUTING.md`,
  `CODE_OF_CONDUCT.md`, `CITATION.cff`, and `FUNDING.md`.
- Project whitepaper and roadmap.

[Unreleased]: https://github.com/Ciprian-LocalPulse/NeuralCompliance.jl/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/Ciprian-LocalPulse/NeuralCompliance.jl/releases/tag/v0.1.0
