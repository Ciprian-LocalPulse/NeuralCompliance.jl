@testset "Interval Bound Propagation" begin
    # A tiny 2-layer network: 2 inputs -> 3 hidden (ReLU) -> 1 output (sigmoid)
    W1 = [1.0 -1.0; 0.5 0.5; -1.0 1.0]
    b1 = [0.0, 0.1, -0.2]
    W2 = reshape([1.0, -1.0, 0.5], 1, 3)
    b2 = [0.0]

    layers = [DenseLayer(W1, b1, relu), DenseLayer(W2, b2, sigmoid_bound)]

    out = certify_output_bounds(layers, [-1.0, -1.0], [1.0, 1.0])
    @test length(out) == 1
    @test out[1].lo >= 0.0 && out[1].hi <= 1.0   # sigmoid range sanity
    @test out[1].lo <= out[1].hi

    # Tighter input region should give a certified interval no wider
    # than the looser region (soundness/monotonicity of IBP in the
    # input region's width).
    tight = certify_output_bounds(layers, [-0.1, -0.1], [0.1, 0.1])
    loose = certify_output_bounds(layers, [-1.0, -1.0], [1.0, 1.0])
    @test width(tight[1]) <= width(loose[1])

    # A degenerate (point) input interval should propagate to a
    # degenerate output interval matching direct forward evaluation.
    point = certify_output_bounds(layers, [0.3, -0.4], [0.3, -0.4])
    x = [0.3, -0.4]
    h = max.(W1 * x .+ b1, 0.0)
    y = 1 ./ (1 .+ exp.(-(W2 * h .+ b2)))
    @test isapprox(point[1].lo, y[1]; atol = 1e-10)
    @test isapprox(point[1].hi, y[1]; atol = 1e-10)
end

@testset "run_compliance_audit orchestration" begin
    W1 = [1.0 0.5; -0.5 1.0]
    b1 = [0.0, 0.0]
    W2 = reshape([1.0, 1.0], 1, 2)
    b2 = [0.0]
    layers = [DenseLayer(W1, b1, relu), DenseLayer(W2, b2, sigmoid_bound)]

    constraints = AbstractConstraint[BoundConstraint("output_in_unit_interval", 0.0, 1.0)]
    report = run_compliance_audit("toy_model", layers, [-1.0, -1.0], [1.0, 1.0], constraints)

    @test report.model_name == "toy_model"
    @test length(report.results) == 1
    @test overall_passed(report)  # sigmoid output is always in [0,1]
end

@testset "Adversarial stress testing" begin
    Random.seed!(42)
    f(x) = sum(x .^ 2)  # simple, well-behaved scalar function
    x0 = [1.0, 1.0]

    report = adversarial_stress_test(f, x0, 0.1; n_samples = 200)
    @test report.n_samples == 200
    @test report.max_output_deviation >= report.mean_output_deviation
    @test report.max_output_deviation >= 0.0

    # A tolerant threshold should be flagged robust; an impossible one
    # (negative) should never be robust.
    lenient = adversarial_stress_test(f, x0, 0.1; n_samples = 50, tolerance = 1e6)
    @test lenient.robust
    strict = adversarial_stress_test(f, x0, 0.1; n_samples = 50, tolerance = -1.0)
    @test !strict.robust
end

@testset "estimate_lipschitz" begin
    Random.seed!(7)
    # f(x) = 3x is globally 3-Lipschitz; empirical estimate should be
    # close to (and never exceed, up to floating point noise) 3.
    f(x) = 3.0 .* x
    L = estimate_lipschitz(f, [0.0, 0.0], 1.0; n_samples = 300)
    @test L <= 3.0 + 1e-8
    @test L > 0.0
end
