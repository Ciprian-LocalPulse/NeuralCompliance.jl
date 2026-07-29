@testset "Audit report generation" begin
    c1 = BoundConstraint("score_range", 0.0, 1.0)
    r1 = check_constraint(c1, Interval(0.2, 0.8))       # pass
    r2 = check_constraint(c1, Interval(-0.1, 1.3))      # fail

    report = generate_report("demo_model", [1.0 2.0; 3.0 4.0], [r1, r2])

    @test report.model_name == "demo_model"
    @test !overall_passed(report)
    @test highest_failing_risk(report) == HIGH   # default risk level of BoundConstraint

    md = to_markdown(report)
    @test occursin("Compliance Audit Report", md)
    @test occursin("demo_model", md)
    @test occursin("NON-COMPLIANT", md)

    js = to_json(report)
    @test occursin("\"model_name\":\"demo_model\"", js)
    @test occursin("\"overall_passed\":false", js)
end

@testset "model_fingerprint determinism" begin
    data1 = ([1.0 2.0; 3.0 4.0], [0.1, 0.2])
    data2 = ([1.0 2.0; 3.0 4.0], [0.1, 0.2])
    data3 = ([1.0 2.0; 3.0 4.1], [0.1, 0.2])

    @test model_fingerprint(data1) == model_fingerprint(data2)
    @test model_fingerprint(data1) != model_fingerprint(data3)
    @test length(model_fingerprint(data1)) == 64  # SHA-256 hex digest
end

@testset "write_report round-trip" begin
    c1 = BoundConstraint("score_range", 0.0, 1.0)
    r1 = check_constraint(c1, Interval(0.2, 0.8))
    report = generate_report("io_model", [0.0], [r1])

    mktempdir() do dir
        path_md = joinpath(dir, "report.md")
        write_report(report, path_md; format = :markdown)
        @test isfile(path_md)
        @test occursin("io_model", read(path_md, String))

        path_json = joinpath(dir, "report.json")
        write_report(report, path_json; format = :json)
        @test isfile(path_json)
        @test occursin("io_model", read(path_json, String))

        @test_throws ArgumentError write_report(report, joinpath(dir, "x.txt"); format = :bogus)
    end
end

@testset "risk_score aggregation" begin
    passing = ComplianceResult("a", true, HIGH)
    failing_low = ComplianceResult("b", false, LOW)
    failing_critical = ComplianceResult("c", false, CRITICAL)

    @test risk_score(ComplianceResult[]) == 0.0
    @test risk_score([passing]) == 0.0
    @test risk_score([failing_critical]) == 1.0
    @test 0.0 < risk_score([passing, failing_low]) < 1.0
end
