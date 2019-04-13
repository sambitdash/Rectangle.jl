import Base: ==, convert, promote_rule, length, reverse, show, div

struct Line{T <: Number}
    sxv::T
    syv::T
    exv::T
    eyv::T
    function Line{T}(m::Matrix{T}) where T <: Number
        @assert size(m) == (2, 2) "Invalid values."
        new(m[1, 1], m[2, 1], m[1, 2], m[2, 2])
    end
    Line{T}(sxv::T, syv::T, exv::T, eyv::T) where T <: Number =
        new(sxv, syv, exv, eyv)
end

Line(m::Matrix{T}) where {T <: Number} = Line{T}(m)

sx(l::Line) = l.sxv
sy(l::Line) = l.syv
ex(l::Line) = l.exv
ey(l::Line) = l.eyv

start(l::Line) = (sx(l), sy(l))
start(l::Line, coord::Int) = coord == 1 ? sx(l) : sy(l)
endof(l::Line) = (ex(l), ey(l))
endof(l::Line, coord::Int) = coord == 1 ? ex(l) : ey(l)
point(l::Line, id::Int=1) = id == 1 ? start(l) : endof(l)

matrix(l::Line) = [sx(l) ex(l); sy(l) ey(l)]
coord(l::Line, axis::Int) = axis == 1 ? (sx(l), ex(l)) : (sy(l), ey(l))

xplot(l::Line) = [sx(l), ex(l)]
yplot(l::Line) = [sy(l), ey(l)]

area(::Line{T}) where {T <:Number} = zero(T)

function Line(lx::Number, ly::Number, rx::Number, ry::Number)
    t = promote(lx, ly, rx, ry)
    return Line{eltype(t)}(t...)
end

function convert(::Type{Line{T}}, l::Line{S}) where {T <: Number, S <: Number}
    S === T && return l
    return Line(convert(T, sx(l)), convert(T, sy(l)),
                convert(T, ex(l)), convert(T, ey(l)))
end

promote_rule(::Type{Line{T}}, ::Type{Line{S}}) where {T <: Number, S <: Number} =
    Line{promote_type(T, S)}

show(io::IO, l::Line) =
    print(io, "Line:[$(sx(l)) $(sy(l)) $(ex(l)) $(ey(l))]")

==(l1::Line{T}, l2::Line{T}) where {T <: Number} =
    abs(sx(l1) - sx(l2)) <= pcTol(T) &&
    abs(sy(l1) - sy(l2)) <= pcTol(T) &&
    abs(ex(l1) - ex(l2)) <= pcTol(T) &&
    abs(ey(l1) - ey(l2)) <= pcTol(T)
==(l1::Line, l2::Line) = ==(promote(l1, l2)...)

reverse(l::Line) = Line(ex(l), ey(l), sx(l), sy(l))

axis_parallel(l::Line{T}; dir::Int=1) where {T <: Number} =
    dir == 2 ? isHorizontal(l) : isVertical(l)


"""
```
    isHorizontal(l::Line) -> Bool
    isVertcal(l::Line) -> Bool
```
If the `Line` is horizontal or vertical.
"""
isHorizontal(l::Line) = iszero(sy(l) - ey(l))
isVertical(l::Line)   = iszero(sx(l) - ex(l))

"""
```
    length(l::Line) -> Float64
```
The length of the line segment.
"""
function length(l::Line)
    dx = ex(l) - sx(l)
    dy = ey(l) - sy(l)
    return sqrt(dx*dx + dy*dy)
end

"""
```
    ratio(l1::Line{T}, p::Vector{T}) -> r::Real
```
If `p` is on `l1` it divides the line at ratio `r:(1-r)` else nothing.
"""
function ratio(l::Line{T}, p::Tuple{T, T}) where {T <: Real}
    dv = (ex(l) - sx(l), ey(l) - sy(l))
    sl = start(l)
    dp = (p[1] - sl[1], p[2] - sl[2])
    r, c = !iszero(dv[1]) ? (dp[1] / dv[1], 1) : (dp[2] / dv[2], 2)
    if c == 1
        tp = dv[2]*r + l.syv
        iszero(tp - p[2]) && return r
    else
        iszero(dp[1]) && return r
    end
    return nothing
end

ratio(l::Line{T}, p::Tuple{S, S}) where {T <: Number, S <: Number} = 
    (ST = promote_type(S, T);
     ratio(convert(Line{ST}, l), convert(Tuple{ST, ST}, p)))

div(l::Line{T}, r::R) where {T <: Number, R <: Real} =
    (sx(l)*(one(R) - r) + ex(l)*r, sy(l)*(one(R) - r) + ey(l)*r)


"""
```
    intersects(l1::Line{T}, l2::Line{T}) where {T <: Real} -> Bool
```
If `l1` and `l2` intersect each other. 
"""
function intersects(l1::Line{T}, l2::Line{T}) where T <: Real
    l = Matrix{Line{T}}(undef, 2, 2)
    l[1, 1] = l[2, 2] = l1
    l[1, 2] = l[2, 1] = l2

    l1l21 = parallelogram_area(start(l1), endof(l1), start(l2))
    l1l22 = parallelogram_area(start(l1), endof(l1), endof(l2))
    l2l11 = parallelogram_area(start(l2), endof(l2), start(l1))
    l2l12 = parallelogram_area(start(l2), endof(l2), endof(l1))
    t = [l1l21 l1l22; l2l11 l2l12]

    for i = 1:2
        for j = 1:2 
            if iszero(t[i, j])
                r = ratio(l[i, 1], point(l[i, 2], j))
                r === nothing && continue
                zero(T) <= notvoid(r) <= one(T) && return true
            end
        end
    end
    return t[1, 1]*t[1, 2] < zero(T) && t[2, 1]*t[2, 2] < zero(T)
end

intersects(l1::Line, l2::Line) = intersects(promote(l1, l2)...)

"""
```
    merge_axis_aligned(alines::Vector{Line{T}}, 
                       axis::Int=1, 
                       order::Symbol=:increasing,
                       tol::T=pcTol(T)) -> Vector{Line{T}}
```
Given an array of axis aligned lines, if the line ends touch or have an overlap
the lines are merged into a larger segment. Lines which are not touching the
other lines are left intact.

`order` parameter can be in `:increasing` or `:decreasing` order in the direction
of the axis. 

`axis` parameter can be `1` for horizontal lines and `2` for vertical lines. 
"""
function merge_axis_aligned(alines::Vector{Line{T}},
                            axis::Int=1,
                            order::Symbol=:increasing,
                            tol::T=pcTol(T)) where {T}
    length(alines) == 0 && return Line{T}[]
    pl = alines[1]
    m = matrix(pl)
    oaxis = axis == 1 ? 2 : 1
    vl = Vector{Line{T}}()
    for i = 2:length(alines)
        l = alines[i]
        if iszero(start(l, oaxis) - start(pl, oaxis), tol)
            if order === :increasing && start(l, axis) - endof(pl, axis) <= tol
                m[axis, 2] = max(endof(l, axis),  endof(pl, axis))
            elseif order === :decreasing &&
                start(pl, axis) - endof(l, axis) <= tol
                m[axis, 1] = min(start(l, axis), start(pl, axis))
            else
                push!(vl, Line{T}(m))
                m = matrix(l)
            end
        else
            push!(vl, Line{T}(m))
            m = matrix(l)
        end
        pl = l
    end
    push!(vl, Line{T}(m))
    return vl
end

function intersect_axis_aligned(hl::Line{T},
                                vl::Line{T}, tol::T) where T <: Number
    x, y  = sx(vl), sy(hl)
    
    sx(hl) > ex(hl) && (hl = reverse(hl))
    sy(vl) > ey(vl) && (vl = reverse(vl))

    return sx(hl) - tol <= x <= ex(hl) + tol &&
           sy(vl) - tol <= y <= ey(vl) + tol ? T[x, y] : T[]
end

function intersect_axis_aligned(hl::Line{T1},
                                vl::Line{T2},
                                tol::T=pcTol(T)) where {T1 <: Number,
                                                        T2 <: Number,
                                                        T  <: Number}
    ST = promote_type(T1, T2, T)
    return intersect_axis_aligned(convert(Line{ST}, hl),
                                  convert(Line{ST}, vl),
                                  convert(ST, tol))
end

"""
    `isless` function  that can be used to sort horizonal lines in descending
    order (top to bottom).
"""
horiz_desc(l1::Line{T1},
           l2::Line{T2},
           tol::Union{T1, T2}=pcTol(promote_type(T1, T2))) where {T1 <: Number,
                                                                  T2 <: Number} =
    horiz_desc(convert(Line{promote_type(T1, T2)}, l1),
               convert(Line{promote_type(T1, T2)}, l2), tol)

@inline function horiz_desc(l1::Line{T}, l2::Line{T},
                            tol::T=pcTol(T)) where T <: Number
    dy = sy(l1) - sy(l2)
    dy > tol && return true
    return iszero(dy, tol) && sx(l1) - sx(l2) < -tol
end

"""
    `isless` function  that can be used to sort vertical lines in ascending
    order (left to right).
"""
vert_asc(l1::Line{T1},
         l2::Line{T2},
         tol::Union{T1, T2}=pcTol(promote_type(T1, T2))) where {T1 <: Number,
                                                                T2 <: Number} =
    vert_asc(convert(Line{promote_type(T1, T2)}, l1),
             convert(Line{promote_type(T1, T2)}, l2), tol)

@inline function vert_asc(l1::Line{T}, l2::Line{T},
                          tol::T=pcTol(T)) where T <: Number
    dx = sx(l1) - sx(l2)
    dx < -tol && return true
    return iszero(dx, tol) && ey(l1) - ey(l2) > tol
end
