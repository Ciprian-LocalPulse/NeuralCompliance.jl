---
name: Compliance / methodology question
about: Ask about what a certification result does or does not guarantee
title: "[Compliance]: "
labels: compliance-question
assignees: ''
---

## Context

What are you trying to certify, and in what environment (e.g. model
risk management, regulatory audit, internal governance review)?

## The specific question

Be as precise as possible. Examples of the kind of question this
template is for:

- "Does a passing `BoundConstraint` check via `propagate_bounds`
  guarantee the bound holds for *every* input in the region, or only
  for the inputs I tested?"
- "What exactly does `estimate_lipschitz` certify, and what does it
  *not* certify?"
- "Is a `MonotonicityConstraint` check a sound, region-wide guarantee,
  or an empirical one?"

## What you've already checked

- [ ] I've read [`COMPLIANCE_METHODOLOGY.md`](../../COMPLIANCE_METHODOLOGY.md)
- [ ] I've read the relevant docstring / API reference entry
- [ ] I've checked whether the `details` dict of the `ComplianceResult` includes a `:method` key, and what it says

## Additional context

Anything else relevant — regulatory framework you're working against, model architecture, etc. Please do not include confidential model details or proprietary data in this public issue.
