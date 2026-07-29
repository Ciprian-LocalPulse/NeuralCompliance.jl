---
name: Bug report
about: Report incorrect behavior, including unsound bounds or audit-report issues
title: "[BUG] "
labels: bug
assignees: ''
---

## Description

A clear description of what's wrong.

## Severity

- [ ] Correctness issue (e.g. unsound bounds, a constraint that can be
      bypassed, a non-reproducible audit fingerprint) — please also see
      [SECURITY.md](../../SECURITY.md) if this could mislead a compliance
      decision.
- [ ] Crash / error
- [ ] Documentation or usability issue

## Minimal reproduction

```julia
using NeuralCompliance

# minimal code that reproduces the issue
```

## Expected behavior

What you expected to happen.

## Actual behavior

What actually happened. Include the full error message or stack trace if
applicable.

## Environment

- `NeuralCompliance.jl` version / commit:
- Julia version (`julia --version`):
- OS:

## Additional context

Anything else relevant (e.g. whether this affects the sound IBP path, the
Monte Carlo stress-testing path, or both).
