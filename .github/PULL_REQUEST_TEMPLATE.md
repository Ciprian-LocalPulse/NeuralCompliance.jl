## Summary

What does this PR change, and why?

## Type of change

- [ ] Bug fix
- [ ] New feature
- [ ] Soundness fix (changes what a certification result guarantees — see below)
- [ ] Documentation
- [ ] Refactor / internal, no behavior change
- [ ] CI / tooling

## Soundness impact

> If this PR touches `src/validation/interval_bounds.jl`,
> `src/core/constraints.jl`, or anything else in the certified path,
> please answer explicitly:

- Does this change what any `check_constraint` method certifies? (Y/N)
- If yes, does the `:method` key in the resulting `ComplianceResult.details` still accurately describe the guarantee being made?
- Were `test/test_constraints.jl` / `test/test_validation.jl` updated to cover the change?

## Checklist

- [ ] `Pkg.test()` passes locally
- [ ] Code formatted per `.JuliaFormatter.toml` (`using JuliaFormatter; format(".")`)
- [ ] Docstrings added/updated for any new or changed public API
- [ ] `CHANGELOG.md` updated under `[Unreleased]`
- [ ] Relevant `ROADMAP.md` item checked off, if applicable

## Related issues

Closes #
