using LinearAlgebra

import Base: iszero

pcTol(::Type{T}) where {T <: Integer}       = zero(T)
pcTol(::Type{T}) where {T <: Rational}      = zero(T)
pcTol(::Type{T}) where {T <: Float32}       = T(1f-3)
pcTol(::Type{T}) where {T <: Float64}       = T(1e-6) 

iszero(n::T, tol::T=pcTol(T)) where {T <: Number} = -tol <= n <= tol

const notvoid = Base.notnothing
const _nv = notvoid

"""
```
    parallelogram_area(m::Matrix) -> Number
```
Area of the parallelogram. The matrix is a 2x3 matrix.
"""
function parallelogram_area(p1::Tuple{T, T},
                            p2::Tuple{T, T},
                            p3::Tuple{T, T}) where T <: Number
    v1 = (p2[1]-p3[1], p2[2]-p3[2])
    v2 = (p3[1]-p1[1], p3[2]-p1[2])
    v3 = (p1[1]-p2[1], p1[2]-p2[2])
    v = max(dot(v1, v1), dot(v2, v2), dot(v3, v3))
    
    d = v3[1]*v1[2] - v1[1]*v3[2]

    v*pcTol(T)*pcTol(T) >= d*d && return zero(T)
    return d
end

