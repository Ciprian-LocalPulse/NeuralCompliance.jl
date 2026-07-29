using NeuralCompliance
using Test
using Random

@testset "NeuralCompliance.jl" begin
    include("test_constraints.jl")
    include("test_validation.jl")
    include("test_audit.jl")
end
