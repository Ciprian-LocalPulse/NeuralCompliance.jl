---
name: Bug report
about: Report incorrect behavior in NeuralCompliance.jl
title: "[Bug]: "
labels: bug
assignees: ''
---

## Summary

A clear, one- or two-sentence description of what's wrong.

## Is this a soundness bug?

> ⚠️ If this bug means `check_constraint` or `propagate_bounds` can
> report `passed = true` for a model that actually violates its
> constraint, please say so explicitly here and label the issue
> `soundness-bug`. These are treated as highest priority, since a false
> "certified compliant" result is the single worst failure mode this
> package can have.

- [ ] Yes, this affects the correctness of a certification result
- [ ] No, this is a different kind of bug (docs, ergonomics, performance, etc.)

## Environment

- `NeuralCompliance.jl` version:
- Julia version (`versioninfo()`):
- OS:

## Minimal reproducible example

```julia
using NeuralCompliance

# Paste the smallest possible code snippet that reproduces the issue.
```

## Expected behavior

What you expected to happen.

## Actual behavior

What actually happened. Include the full error message / stack trace if there is one.

## Additional context

Anything else that might help — related constraints, model architecture, links to relevant `ROADMAP.md` items, etc.
