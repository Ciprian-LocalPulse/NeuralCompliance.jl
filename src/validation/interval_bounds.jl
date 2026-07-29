"""
Interval arithmetic and Interval Bound Propagation (IBP).

This module implements sound (conservative) forward propagation of
input intervals through affine (dense) layers and common
elementwise activations, producing a certified output interval that
is guaranteed to contain the true output for *every* input inside the
input interval. This is the workhorse used to certify
[`BoundConstraint`](@ref)s without exhaustive enumeration.

Reference technique: Interval Bound Propagation, as used in formal
verification of neural networks (Gowal et al., 2018 and related
reachability-analysis literature).
"""

# ---------------------------------------------------------------------------
# Interval type and arithmetic
# ---------------------------------------------------------------------------

"""
    Interval{T<:Real}

A closed real interval `[lo, hi]`. Supports elementwise arithmetic
needed for sound bound propagation through linear layers and common
activations.
"""
struct Interval{T <: Real}
    lo::T
    hi::T
    function Interval(lo::T, hi::T) where {T <: Real}
        lo <= hi || throw(ArgumentError("Interval requires lo <= hi, got [$lo, $hi]"))
        new{T}(lo, hi)
    end
end

Interval(x::Real) = Interval(promote(x, x)...)
width(i::Interval) = i.hi - i.lo
midpoint(i::Interval) = (i.lo + i.hi) / 2

Base.:+(a::Interval, b::Interval) = Interval(a.lo + b.lo, a.hi + b.hi)
Base.:+(a::Interval, b::Real) = Interval(a.lo + b, a.hi + b)
Base.:-(a::Interval) = Interval(-a.hi, -a.lo)
Base.:-(a::Interval, b::Interval) = a + (-b)

function Base.:*(a::Interval, b::Interval)
    candidates = (a.lo * b.lo, a.lo * b.hi, a.hi * b.lo, a.hi * b.hi)
    Interval(minimum(candidates), maximum(candidates))
end

function Base.:*(k::Real, a::Interval)
    k >= 0 ? Interval(k * a.lo, k * a.hi) : Interval(k * a.hi, k * a.lo)
end
Base.:*(a::Interval, k::Real) = k * a

Base.in(x::Real, i::Interval) = i.lo <= x <= i.hi
Base.issubset(a::Interval, b::Interval) = b.lo <= a.lo && a.hi <= b.hi

"""
    relu(i::Interval) -> Interval

Sound elementwise ReLU of an interval: `[max(lo,0), max(hi,0)]`.
"""
relu(i::Interval) = Interval(max(i.lo, zero(i.lo)), max(i.hi, zero(i.hi)))

"""
    sigmoid_bound(i::Interval) -> Interval

Sound elementwise sigmoid of an interval. Sigmoid is monotonic, so the
image of an interval under sigmoid is exactly `[sigmoid(lo),
sigmoid(hi)]`.
"""
sigmoid_bound(i::Interval) = Interval(1 / (1 + exp(-i.lo)), 1 / (1 + exp(-i.hi)))

"""
    tanh_bound(i::Interval) -> Interval

Sound elementwise tanh of an interval (tanh is monotonic).
"""
tanh_bound(i::Interval) = Interval(tanh(i.lo), tanh(i.hi))

# ---------------------------------------------------------------------------
# Dense layer propagation
# ---------------------------------------------------------------------------

"""
    DenseLayer

A single affine layer `y = W*x + b` followed by an elementwise
activation function `act` (must accept and return `Interval` or
`Vector{<:Real}` uniformly, e.g. [`relu`](@ref), [`sigmoid_bound`](@ref),
`identity`).
"""
struct DenseLayer{W <: AbstractMatrix, B <: AbstractVector, F <: Function}
    weights::W
    bias::B
    activation::F
end

"""
    propagate_bounds(layers::Vector{<:DenseLayer}, input::AbstractVector{<:Interval})
        -> Vector{<:Interval}

Propagates a vector of per-coordinate input intervals through a stack
of [`DenseLayer`](@ref)s using sound interval arithmetic, returning the
certified output interval vector.

This is the core primitive used to certify [`BoundConstraint`](@ref)s:
if the certified output interval satisfies the required bound, the
model is *provably* compliant for every point inside the input
region -- not merely for observed samples.
"""
function propagate_bounds(layers::Vector{<:DenseLayer}, input::AbstractVector{<:Interval})
    x = input
    for layer in layers
        x = affine_propagate(layer.weights, layer.bias, x)
        x = layer.activation.(x)
    end
    return x
end

"""
    affine_propagate(W, b, x::AbstractVector{<:Interval}) -> Vector{<:Interval}

Sound propagation of an interval vector `x` through the affine map
`y = W*x + b`, using the classical center-radius decomposition:

    y_i = c_i ± r_i,  where c = W*midpoint(x) + b,  r = |W|*radius(x)

This is the numerically preferred formulation (avoids catastrophic
cancellation relative to naive lo/hi products) and is `O(n*m)` for a
dense `m x n` weight matrix, matching ordinary matrix-vector cost.
"""
function affine_propagate(W::AbstractMatrix, b::AbstractVector, x::AbstractVector{<:Interval})
    centers = midpoint.(x)
    radii = width.(x) ./ 2
    c = W * centers .+ b
    r = abs.(W) * radii
    return Interval.(c .- r, c .+ r)
end

"""
    certify_output_bounds(layers, input_lo, input_hi) -> Vector{Interval}

Convenience wrapper: builds per-coordinate input intervals from
elementwise lower/upper vectors and propagates them through `layers`.
"""
function certify_output_bounds(
    layers::Vector{<:DenseLayer}, input_lo::AbstractVector{<:Real}, input_hi::AbstractVector{<:Real}
)
    length(input_lo) == length(input_hi) ||
        throw(ArgumentError("input_lo and input_hi must have the same length"))
    input = Interval.(input_lo, input_hi)
    propagate_bounds(layers, input)
end
