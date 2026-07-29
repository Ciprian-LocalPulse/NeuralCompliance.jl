# Security Policy

## Supported versions

`NeuralCompliance.jl` is currently pre-1.0 (`0.x`). Security fixes are
applied to the latest release on the `main` branch. There is no long-term
support branch yet.

| Version | Supported |
| ------- | --------- |
| 0.1.x   | ✅        |
| < 0.1   | ❌        |

## Reporting a vulnerability

If you believe you've found a security issue — including, but not limited
to, a correctness bug in the bound-propagation or constraint-checking logic
that could cause the library to *silently* certify a non-compliant model as
compliant — please report it privately rather than opening a public issue.

**Preferred channel:** open a
[GitHub Security Advisory](https://github.com/Ciprian-LocalPulse/NeuralCompliance.jl/security/advisories/new)
for this repository. This notifies the maintainer without disclosing the
issue publicly.

**Alternative:** email the maintainer at the address listed in
[`CITATION.cff`](CITATION.cff), with a subject line starting with
`[SECURITY]`.

Please include:

- A description of the issue and its potential impact (e.g. unsound
  bounds, incorrect audit-report fingerprints, a constraint that can be
  bypassed).
- Steps to reproduce, ideally a minimal Julia snippet.
- The version/commit you tested against.

## What to expect

- Acknowledgement of your report within a reasonable timeframe.
- An assessment of severity and, for confirmed issues, a fix released as
  soon as practical, with credit to the reporter unless anonymity is
  requested.
- Because this library is used to produce compliance evidence, any issue
  that could cause a false "compliant" result is treated as high severity
  regardless of how it was introduced.

## Scope

This policy covers the `NeuralCompliance.jl` source code itself. It does
not cover models, data, or downstream systems that use the library — those
remain the responsibility of the deploying organization.
