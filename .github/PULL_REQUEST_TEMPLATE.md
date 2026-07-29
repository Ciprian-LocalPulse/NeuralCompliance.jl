## Summary

What does this PR change, and why?

## Type of change

- [ ] Bug fix
- [ ] New feature (constraint family, layer support, report format, etc.)
- [ ] Documentation
- [ ] Refactor / internal (no behavior change)
- [ ] CI / tooling

## Correctness checklist (for changes to `src/core/` or `src/validation/`)

- [ ] New/changed logic is covered by tests in `test/`.
- [ ] If this touches sound bound propagation (`interval_bounds.jl`) or
      constraint checking (`constraints.jl`), I've included a soundness
      justification (why the bounds/checks can't produce a false
      "compliant" result) in the PR description or code comments.
- [ ] If this touches audit reporting (`audit_logger.jl`), I've verified
      fingerprint/provenance determinism still holds.

## Testing

How did you verify this? Include commands run, e.g.:

```bash
julia --project=. -e 'using Pkg; Pkg.test()'
```

## Related issues

Closes #

## Checklist

- [ ] I've read [CONTRIBUTING.md](../CONTRIBUTING.md).
- [ ] Code is formatted per `.JuliaFormatter.toml` / Blue style.
- [ ] I've updated [CHANGELOG.md](../CHANGELOG.md) under `[Unreleased]`.
- [ ] I've updated documentation in `docs/` if public API changed.
