__precompile__()

module Rectangle

export  Rect,
            w, h, area, perimeter,
            union, intersect, inside,
            to_plot_shape,
            projectX, projectY,
            avg_min_dist

import Base: ==, union, intersect

struct Rect{T <: Number}
    m::Matrix{T}
    function Rect{T}(m::Matrix{T}) where {T <: Number}
        @assert size(m) == (2,2) && all(lb(m) .< ru(m)) "Invalid values."
        new(m)
    end
end



Rect(lx::T, ly::T, rx::T, ry::T) where {T <: Number} = Rect{T}(Matrix([lx rx; ly ry]))

lb(r) = lb(r.m)
ru(r) = ru(r.m)
lb(m::Matrix) = m[:, 1]
ru(m::Matrix) = m[:, 2]
lx(r) = r.m[1, 1]
ly(r) = r.m[2, 1]
rx(r) = r.m[1, 2]
ry(r) = r.m[2, 2]

coord(r, axis) = r.m[axis, :]
x(r) = coord(r, 1)
y(r) = coord(r, 2)
c_lo(r, axis)   = r.m[axis, 1]
c_hi(r, axis)   = r.m[axis, 2]

function union(r1::Rect, r2::Rect)
    l = min.(lb(r1), lb(r2))
    r = max.(ru(r1), ru(r2))
    return Rect(l[1], l[2], r[1], r[2])
end

function intersect(r1::Rect{T}, r2::Rect{T}) where T <: Number
    l = max.(lb(r1), lb(r2))
    r = min.(ru(r1), ru(r2))
    any(l .> r) && return nothing
    return Rect(l[1], l[2], r[1], r[2])
end

pcTol(::Type{T}) where {T <: Integer}  = zero(T)
pcTol(::Type{T}) where {T <: Rational} = zero(T)
pcTol(::Type{T}) where {T <: Real}     = T(1e-6)

==(r1::Rect{T}, r2::Rect{T}) where {T <: Number} = all(abs.(r1.m - r2.m) .<= pcTol(T))

inside(p::Tuple{T, T}, r::Rect{T}) where T <: Number = all(r.m[:, 1] .<= p .<= r.m[:, 2])

inside(ri::Rect, ro::Rect) = intersect(ri, ro) == ri

h(r::Rect) = ry(r) - ly(r)

w(r::Rect) = rx(r) - lx(r)

area(r::Rect) = h(r)*w(r)

perimeter(r::Rect{T}) where T <: Number = T(2)*(h(r) + w(r))

to_plot_shape(r::Rect{T}) where T <: Number =
    ([lx(r), rx(r), rx(r), lx(r)], [ly(r), ly(r), ry(r), ry(r)])

xsort(r1::Rect, r2::Rect, reverse=false) = sortr(r1, r2, reverse=reverse, axis=1)
ysort(r1::Rect, r2::Rect, reverse=false) = sortr(r1, r2, reverse=reverse, axis=2)

sortr(r1::Rect, r2::Rect; reverse=false, axis=1) =
    (!reverse && r1.m[axis, 1] > r2.m[axis, 1]) ? (r2, r1) : (r1, r2)

"""
```
    projectX(r1::Rect, r2::Rect) -> (left, overlap, right)
```
Projects the rectangles along the X-axis and returns three parts of rectangles.

`left`: The left segment of the projection
`overlap`: If there is any overlap between the rectangles
`right`: The right segment of the projection

Each portion is returned as a tuple.

If the rectangle is part of the first rectangle, it's returned as the first element of the
tuple. `nothing` is returned for a part when a portion is not available.
"""
projectX(r1::Rect, r2::Rect) = project(r1, r2, axis=1)

"""
```
    projectX(r1::Rect, r2::Rect) -> (bottom, overlap, top)
```
Projects the rectangles along the X-axis and returns three parts of rectangles.

`bottom`: The bottom segment of the projection
`overlap`: If there is any overlap between the rectangles
`top`: The top segment of the projection

Each portion is returned as a tuple.

If the rectangle is part of the first rectangle, it's returned as the first element of the
tuple. `nothing` is returned for a part when a portion is not available.
"""
projectY(r1::Rect, r2::Rect) = project(r1, r2, axis=2)

function project(r1::Rect{T}, r2::Rect{T}; axis::Int=1) where T
    # l=low and h=high
    lr, hr = sortr(r1, r2, axis=axis)
    flip = lr != r1

    cl = coord(lr, axis)
    ch = coord(hr, axis)
    axl = sort([cl[1], cl[2], ch[1], ch[2]])

    # Low segment
    if c_lo(lr, axis) + pcTol(T) < c_lo(hr, axis)
        lm = copy(lr.m)
        lm[axis, 1] = axl[1]
        lm[axis, 2] = axl[2]
        l = Rect{T}(lm)
        low = !flip ? (l, nothing) : (nothing, l)
        # Non-overlap
        l == lr && return low, (nothing, nothing), !flip ? (nothing, hr) : (hr, nothing)
    else
        low = nothing, nothing
    end

    #Overlap segment
    om1, om2 = copy(r1.m), copy(r2.m)
    om1[axis, 1] = om2[axis, 1] = axl[2]
    om1[axis, 2] = om2[axis, 2] = axl[3]

    overlap = Rect{T}(om1), Rect{T}(om2)

    #Right segment
    if -pcTol(T) <= c_hi(r1, axis) - c_hi(r2, axis) <= pcTol(T)
        high = nothing, nothing
    else
        hm = c_hi(r1, axis) > c_hi(r2, axis) ? copy(r1.m) : copy(r2.m)
        hm[axis, 1] = axl[3]
        hm[axis, 2] = axl[4]
        high = c_hi(r1, axis) > c_hi(r2, axis) ? (Rect{T}(hm), nothing) :
                                                 (nothing, Rect{T}(hm))
    end
    return low, overlap, high
end

function get_overlapped_dist(l, h, f, a1, a2)
    # l = low and h = high
    lr, adl = l[1] == nothing ? (l[2], a2) : (l[1], a1)
    wlal    = lr   == nothing ? zero(a1)   : f(lr)*area(lr)

    hr, adh = h[1] == nothing ? (h[2], a2) : (h[1], a1)
    whah    = hr   == nothing ? zero(a1)   : f(hr)*area(hr)

    d = Float64(wlal)/Float64(adl) + Float64(whah)/Float64(adh)
    return d/2.0
end

"""
```
    avg_min_dist(r1::Rect, r2::Rect) -> dx::Float64, dy::Float64
```
Rectangles are essentially point sets. Hence, one can perceive existence of a minimum
distance of one point in `r1` from `r2`. Similar, distance would also exist for every point
in `r2` from `r1`. While, technically Euclidean distance metric can exist, the computation
is fairly cumborsome. Here, we use the city block distance or L1-metric.

`dx`: The distance in the x-direction
`dy`: The distance in the y-direction

The minimum distance will be `zero` when the rectangles are intersecting.
The distance also will be lower in a specific direction if there is an overlap of the
rectangles in that direction
"""

function avg_min_dist(r1::Rect, r2::Rect)
    intersect(r1, r2) != nothing && return 0.0, 0.0
    h1, h2 = Float64(h(r1)),    Float64(h(r2))
    w1, w2 = Float64(w(r1)),    Float64(w(r2))
    a1, a2 = Float64(area(r1)), Float64(area(r2))

    hg = Float64(min(abs(ry(r2) - ly(r1)), abs(ry(r1) - ly(r2))))
    wg = Float64(min(abs(rx(r2) - lx(r1)), abs(rx(r1) - lx(r2))))

    dy = hg + (h1*a1 + h2*a2)/(2.0*(a1 + a2))
    dx = wg + (w1*a1 + w2*a2)/(2.0*(a1 + a2))

    l, ox, r = projectX(r1, r2)
    ox != (nothing, nothing) && return get_overlapped_dist(l, r, w, a1, a2), dy
    b, oy, t = projectY(r1, r2)
    oy != (nothing, nothing) && return dx, get_overlapped_dist(b, t, h, a1, a2)
    return dx, dy
end

end # module
