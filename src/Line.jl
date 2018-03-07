import Base: ==, convert, promote_rule, length

struct Line{T <: Number}
    m::Matrix{T}
    function Line{T}(m::Matrix{T}) where {T <: Number}
        @assert size(m) == (2, 2) "Invalid values."
        new(m)
    end
    Line{T}(lx::T, ly::T, rx::T, ry::T) where {T <: Number} = new(Matrix([lx rx; ly ry]))
end

Line(m::Matrix{T}) where {T <: Number} = Line{T}(m)

function Line(lx::Number, ly::Number, rx::Number, ry::Number)
    t = promote(lx, ly, rx, ry)
    return Line{typeof(t[1])}(t...)
end

convert(::Type{Line{T}}, r::Line{S}) where {T <: Number, S <: Number} =
    Line{T}(Matrix{T}(r.m))

promote_rule(::Type{Line{T}}, ::Type{Line{S}}) where {T <: Number, S <: Number} =
    Line{promote_type(T, S)}

==(l1::Line{T}, l2::Line{T}) where {T <: Number} = all(abs.(l1.m - l2.m) .<= pcTol(T))
==(r1::Line, r2::Line) = ==(promote(l1, l2)...)


axis_parallel(l::Line{T}; dir::Int=1) where {T <: Number} =
    -pcTol(T) <= l.m[dir, 1] - l.m[dir, 2] <= pcTol(T)

"""
```
    isHorizontal(l::Line) -> Bool
    isVertcal(l::Line) -> Bool
```
If the `Line` is horizontal or vertical.
"""
isHorizontal(l::Line) = axis_parallel(l, dir=2)
isVertical(l::Line)   = axis_parallel(l, dir=1)

"""
```
    length(l::Line) -> Float64
```
The length of the line segment.
"""
length(l::Line) = (v = l.m[:, 1] - l.m[:, 2]; sqrt(dot(v, v)))

"""
```
    ratio(l1::Line{T}, p::Vector{T}) -> r::Real
```
If `p` is on `l1` it divides the line at ratio `r:(1-r)` else nothing.
"""
function ratio(l::Line{T}, p::Vector{T}) where {T <: Real}
    dv = l.m[:, 2] - l.m[:, 1]
    dp = p - l.m[:, 1]
    r, c = dv[1] > pcTol(T) || dv[1] < -pcTol(T) ? (dp[1] / dv[1], 1) : (dp[2] / dv[2], 2)
    if c == 1
        tp = dv[2]*r + l.m[2, 1]
        -pcTol(T) <= tp - dp[2] <= pcTol(T) && return r
    else
        -pcTol(T) <= dp[1] <= pcTol(T) && return r
    end
    return nothing
end

function ratio(l::Line{T}, p::Vector{S}) where {T <: Number, S <: Number}
    l, p = (promote_type(S, T) == T) ? (l, convert(Vector{T}, p)) : (convert(Line{T}, l), p)
    return ratio(l, p)
end

"""
```
    intersects(l1::Line{T}, l2::Line{T}) where {T <: Real} -> Bool
```
If `l1` and `l2` intersect each other. 
"""
function intersects(l1::Line{T}, l2::Line{T}) where {T <: Real}
    l = [l1 l2; l2 l1]
    t = [parallelogram_area(hcat(l1.m, l2.m[:, 1])) parallelogram_area(hcat(l1.m, l2.m[:, 2]));
         parallelogram_area(hcat(l2.m, l1.m[:, 1])) parallelogram_area(hcat(l2.m, l1.m[:, 2]))]

    for i = 1:2
        for j = 1:2 
            if t[i, j] == zero(T)
                r = ratio(l[i, 1], l[i, 2].m[:, j])
                return zero(T) <= r <= one(T)
            end
        end
    end
    t[1, 1]*t[1, 2] < zero(T) && t[2, 1]*t[2, 2] < zero(T) && return true
    return false
end

intersects(l1::Line, l2::Line) = intersects(promote(l1, l2)...)
