"""
Audit report generation.

Turns a batch of [`ComplianceResult`](@ref)s into a durable,
human-readable and machine-readable audit trail, suitable for
attachment to model-risk-management (MRM) documentation packages.
Includes a content hash of the input model/config for provenance, so
that a generated report can be tied unambiguously to a specific model
artifact.
"""

"""
    AuditReport

A complete compliance audit for a single model, aggregating one
[`ComplianceResult`](@ref) per checked constraint.
"""
struct AuditReport
    model_name::String
    model_hash::String
    generated_at::DateTime
    results::Vector{ComplianceResult}
end

"""
    overall_passed(report::AuditReport) -> Bool

Returns `true` if every constraint check in `report` passed.
"""
overall_passed(r::AuditReport) = all(res -> res.passed, r.results)

"""
    highest_failing_risk(report::AuditReport) -> Union{RiskLevel,Nothing}

Returns the highest [`RiskLevel`](@ref) among failing checks, or
`nothing` if the report is fully compliant.
"""
function highest_failing_risk(report::AuditReport)
    failing = [r.risk_level for r in report.results if !r.passed]
    isempty(failing) && return nothing
    return maximum(failing)
end

"""
    model_fingerprint(data) -> String

Computes a stable SHA-256 hex digest of arbitrary model data (e.g. a
tuple of weight matrices) for provenance tracking. Two audit reports
generated from bit-identical model parameters will carry identical
fingerprints, which is the basis for detecting undisclosed model
drift between audit cycles.
"""
function model_fingerprint(data)
    io = IOBuffer()
    _write_stable!(io, data)
    return bytes2hex(sha256(take!(io)))
end

_write_stable!(io::IOBuffer, x::AbstractArray) = (foreach(v -> print(io, v, ";"), x); nothing)
_write_stable!(io::IOBuffer, x::Tuple) = (foreach(v -> _write_stable!(io, v), x); nothing)
_write_stable!(io::IOBuffer, x) = print(io, x, ";")

"""
    generate_report(model_name, model_data, results) -> AuditReport

Assembles an [`AuditReport`](@ref) from a list of `ComplianceResult`s,
fingerprinting `model_data` for provenance.
"""
function generate_report(model_name::AbstractString, model_data, results::Vector{ComplianceResult})
    AuditReport(String(model_name), model_fingerprint(model_data), now(), results)
end

"""
    to_markdown(report::AuditReport) -> String

Renders an [`AuditReport`](@ref) as a Markdown compliance summary,
suitable for direct inclusion in a model-risk documentation package.
"""
function to_markdown(report::AuditReport)
    io = IOBuffer()
    status = overall_passed(report) ? "✅ COMPLIANT" : "❌ NON-COMPLIANT"
    println(io, "# Compliance Audit Report")
    println(io)
    println(io, "| Field | Value |")
    println(io, "|---|---|")
    println(io, "| Model | `$(report.model_name)` |")
    println(io, "| Fingerprint (SHA-256) | `$(report.model_hash)` |")
    println(io, "| Generated at | $(report.generated_at) |")
    println(io, "| Overall status | $status |")
    println(io)
    println(io, "## Constraint Results")
    println(io)
    println(io, "| Constraint | Result | Risk Level | Details |")
    println(io, "|---|---|---|---|")
    for r in report.results
        mark = r.passed ? "PASS" : "**FAIL**"
        detail_str = join(["$(k)=$(v)" for (k, v) in r.details], ", ")
        println(io, "| $(r.constraint_name) | $mark | $(string(r.risk_level)) | $detail_str |")
    end
    return String(take!(io))
end

"""
    to_json(report::AuditReport) -> String

Renders an [`AuditReport`](@ref) as a minimal, dependency-free JSON
string (no external JSON package required, keeping the framework's
dependency footprint small for security-sensitive deployments).
"""
function to_json(report::AuditReport)
    io = IOBuffer()
    print(io, "{")
    print(io, "\"model_name\":\"", _json_escape(report.model_name), "\",")
    print(io, "\"model_hash\":\"", report.model_hash, "\",")
    print(io, "\"generated_at\":\"", report.generated_at, "\",")
    print(io, "\"overall_passed\":", overall_passed(report), ",")
    print(io, "\"results\":[")
    for (i, r) in enumerate(report.results)
        i > 1 && print(io, ",")
        print(io, "{")
        print(io, "\"constraint_name\":\"", _json_escape(r.constraint_name), "\",")
        print(io, "\"passed\":", r.passed, ",")
        print(io, "\"risk_level\":\"", string(r.risk_level), "\",")
        print(io, "\"timestamp\":\"", r.timestamp, "\"")
        print(io, "}")
    end
    print(io, "]}")
    return String(take!(io))
end

_json_escape(s::AbstractString) = replace(s, "\"" => "\\\"")

"""
    write_report(report::AuditReport, path::AbstractString; format=:markdown)

Writes the audit report to disk in `:markdown` or `:json` format,
inferred from `path`'s extension if `format` is not given explicitly.
"""
function write_report(report::AuditReport, path::AbstractString; format::Symbol = :markdown)
    content = if format === :markdown
        to_markdown(report)
    elseif format === :json
        to_json(report)
    else
        throw(ArgumentError("format must be :markdown or :json"))
    end
    open(path, "w") do io
        write(io, content)
    end
    return path
end
