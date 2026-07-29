```@meta
CurrentModule = NeuralCompliance
```

# API Reference

## Core Types

```@docs
RiskLevel
AbstractConstraint
BoundConstraint
LipschitzConstraint
MonotonicityConstraint
ComplianceResult
```

## Interval Arithmetic & Bound Propagation

```@docs
Interval
width
midpoint
relu
sigmoid_bound
tanh_bound
DenseLayer
propagate_bounds
affine_propagate
certify_output_bounds
```

## Constraint Checking

```@docs
check_constraint
```

## Robustness & Stress Testing

```@docs
StressTestReport
adversarial_stress_test
estimate_lipschitz
```

## Audit & Provenance

```@docs
AuditReport
generate_report
to_markdown
to_json
write_report
model_fingerprint
overall_passed
highest_failing_risk
```

## Metrics

```@docs
max_abs_deviation
mean_absolute_error
root_mean_square
interval_tightness
risk_score
```

## Orchestration

```@docs
run_compliance_audit
```
