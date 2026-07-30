# Changelog

All notable changes to `NeuralCompliance.jl` are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- `.gitattributes` to enforce consistent LF line endings across the repo.
- `CHANGELOG.md` (this file).
- `SECURITY.md` with a vulnerability-disclosure process.
- Issue templates (bug report, feature request, compliance question) and a
  pull request template under `.github/`, plus `.github/ISSUE_TEMPLATE/config.yml`
  linking to the security policy and discussions.
- `.github/FUNDING.yml` so GitHub's native "Sponsor" button is active
  (previously only `FUNDING.md` existed at the repo root, which GitHub does
  not read for that button).
- `.github/dependabot.yml` for weekly Julia package and GitHub Actions
  dependency updates.
- `COMPLIANCE_METHODOLOGY.md` at the repository root — a clone-visible
  explanation of what `:interval_bound_propagation` vs. `:empirical_sampling`
  results actually guarantee (the wiki equivalent is not included in
  `git clone`).
- `THREAT_MODEL.md` at the repository root, describing in-scope threats,
  explicit non-goals, and the empirical-vs-certified misuse failure mode.
- `paper.md` / `paper.bib` — a draft JOSS (Journal of Open Source Software)
  submission.
- Explicit `:method => :empirical_sampling` key on
  `check_constraint(::LipschitzConstraint, ...)` and
  `check_constraint(::MonotonicityConstraint, ...)`, for consistency with
  the `:method` key already present on `BoundConstraint` checks.
- Cross-links between `README.md`, `ROADMAP.md`, and `WHITEPAPER.md`.

### Fixed
- Inconsistent repository references (`neuralcompliance/NeuralCompliance.jl`
  vs. `Ciprian-LocalPulse/NeuralCompliance.jl`) in `docs/make.jl`,
  `docs/src/index.md`, and `CITATION.cff`, now aligned with the org used
  everywhere else (README badges, install instructions).
- `.github/workflows/TagBot.yml` to auto-tag and release once
  JuliaRegistrator approves a new version.
- `.github/workflows/CompatHelper.yml` to open automated `[compat]` bump
  PRs for `Dates`, `SHA`, `Statistics`, and other dependencies.
- `Aqua.jl` quality-assurance test (`test/aqua_test.jl`, wired into
  `test/runtests.jl`) covering method ambiguities, unbound type
  parameters, undocumented exports, stale/undeclared dependencies, and
  type piracy.
- `benchmark/` folder with a `BenchmarkTools.jl` suite
  (`bench_interval_bounds.jl`) for interval bound propagation
  performance across small/medium/large model sizes.
- `.github/FUNDING.yml` so GitHub's native "❤️ Sponsor" button surfaces
  the project's PayPal link directly in the repo header.
- `.github/dependabot.yml` to keep GitHub Actions versions
  (`actions/checkout`, etc.) patched.
- `.github/CODEOWNERS` requiring maintainer review on all pull requests.
- Second example, `examples/black_box_stress_test.jl`, demonstrating the
  empirical (Monte Carlo stress-testing) validation path for
  vendor-supplied black-box models, per WHITEPAPER.md §6.
- `CHANGELOG.md` is now mirrored into `docs/src/changelog.md` at build
  time (`docs/make.jl`) so it appears in the rendered documentation site.

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
