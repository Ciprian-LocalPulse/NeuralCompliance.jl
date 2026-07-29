@testset "Interval arithmetic" begin
    a = Interval(-1.0, 2.0)
    b = Interval(0.5, 1.0)

    @test width(a) == 3.0
    @test midpoint(a) == 0.5

    c = a + b
    @test c.lo == -0.5 && c.hi == 3.0

    d = a * b
    @test d.lo == -1.0   # -1.0 * 1.0
    @test d.hi == 2.0    #  2.0 * 1.0

    r = relu(a)
    @test r.lo == 0.0 && r.hi == 2.0

    @test 0.0 in a
    @test !(3.0 in a)

    @test_throws ArgumentError Interval(2.0, 1.0)
end

@testset "BoundConstraint construction" begin
    @test_throws ArgumentError BoundConstraint("bad", 1.0, 0.0)
    c = BoundConstraint("prob_output", 0.0, 1.0)
    @test c.lower == 0.0 && c.upper == 1.0
end

@testset "check_constraint: BoundConstraint on Interval" begin
    c = BoundConstraint("score", 0.0, 1.0)

    ok = check_constraint(c, Interval(0.1, 0.9))
    @test ok.passed

    bad = check_constraint(c, Interval(-0.1, 0.9))
    @test !bad.passed
    @test bad.details[:certified_lower] == -0.1
end

@testset "check_constraint: BoundConstraint on samples" begin
    c = BoundConstraint("score", 0.0, 1.0)
    samples = [0.1, 0.5, 0.99, 1.2]  # one violation

    res = check_constraint(c, samples)
    @test !res.passed
    @test res.details[:n_violations] == 1
end

@testset "check_constraint: LipschitzConstraint" begin
    c = LipschitzConstraint("smoothness", 5.0)
    good = check_constraint(c, 3.2)
    bad = check_constraint(c, 7.5)
    @test good.passed
    @test !bad.passed
    @test bad.details[:margin] < 0
end

@testset "check_constraint: MonotonicityConstraint" begin
    c_inc = MonotonicityConstraint("dti_monotonic", 1, :increasing)
    xs = collect(0.0:0.1:1.0)

    ys_increasing = xs .^ 2
    res = check_constraint(c_inc, xs, ys_increasing)
    @test res.passed

    ys_non_monotonic = sin.(10 .* xs)
    res2 = check_constraint(c_inc, xs, ys_non_monotonic)
    @test !res2.passed
    @test res2.details[:n_violations] > 0

    @test_throws ArgumentError MonotonicityConstraint("bad", 1, :sideways)
end
