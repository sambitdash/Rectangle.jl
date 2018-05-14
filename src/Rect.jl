using IntervalTrees

import Base: ==, union, intersect, promote_rule, convert, show

struct Rect{T <: Number}
    m::Matrix{T}
    function Rect{T}(m::Matrix{T}) where {T <: Number}
        @assert size(m) == (2,2) && all(lb(m) .< ru(m)) "Invalid values."
        new(m)
    end
    Rect{T}(lx::T, ly::T, rx::T, ry::T) where {T <: Number} =
        new(Matrix([min(lx, rx) max(lx, rx); min(ly, ry) max(ly, ry)]))
end

Rect(m::Matrix{T}) where {T <: Number} = Rect{T}(m)

function Rect(lx::Number, ly::Number, rx::Number, ry::Number)
    t = promote(lx, ly, rx, ry)
    return Rect{typeof(t[1])}(t...)
end

convert(::Type{Rect{T}}, r::Rect{S}) where {T <: Number, S <: Number} =
    Rect{T}(Matrix{T}(r.m))

promote_rule(::Type{Rect{T}}, ::Type{Rect{S}}) where {T <: Number, S <: Number} =
    Rect{promote_type(T, S)}

show(io::IO, r::Rect) = print(io, "Rect:[$(lx(r)) $(ly(r)) $(rx(r)) $(ry(r))]")

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

hlines(r::Rect) = [Line(lx(r), ly(r), rx(r), ly(r)), Line(lx(r), ry(r), rx(r), ry(r))]
vlines(r::Rect) = [Line(lx(r), ly(r), lx(r), ry(r)), Line(rx(r), ly(r), rx(r), ry(r))]
lines(r::Rect)  = [hlines(r)..., vlines(r)...]
olines(r::Rect) = (ls = lines(r); [ls[1], ls[4], reverse(ls[2]), reverse(ls[3])])
diags(r::Rect)  = [Line(lx(r), ly(r), rx(r), ry(r)), Line(rx(r), ly(r), lx(r), ry(r))]
cg(r::Rect) = div(diags(r)[1], 1//2)

function union(r1::Rect, r2::Rect)
    l = min.(lb(r1), lb(r2))
    r = max.(ru(r1), ru(r2))
    return Rect(l[1], l[2], r[1], r[2])
end

union(r1::Rect, r2::Rect, y...) = union(r1, union(r2, y...))
union(r::Rect) = r

intersect(r1::Rect, r2::Rect) = intersect(promote(r1, r2)...)

function intersect(r1::Rect{T}, r2::Rect{T}) where T <: Number
    l = max.(lb(r1), lb(r2))
    r = min.(ru(r1), ru(r2))
    l1 = l + pcTol(T)
    any(l1 .>= r) && return nothing
    return Rect(l[1], l[2], r[1], r[2])
end

==(r1::Rect{T}, r2::Rect{T}) where {T <: Number} = all(abs.(r1.m - r2.m) .<= pcTol(T))
==(r1::Rect, r2::Rect) = ==(promote(r1, r2)...)

inside(p::Tuple{T, T}, r::Rect{T}) where T <: Number = all(r.m[:, 1] .<= p .<= r.m[:, 2])

inside(p::Tuple{T, T}, r::Rect{S}) where {T <: Number, S <: Number} =
    (ST = promote_type(S, T); inside(convert(Tuple{ST, ST}, p), convert(Rect{ST}, r)))

inside(ri::Rect, ro::Rect) = intersect(ri, ro) == ri

intersects(r1::Rect, r2::Rect) = intersect(r1, r2) != nothing

function intersects(r::Rect, l::Line)
    ml = l.m
    (inside((ml[1, 1], ml[2, 1]), r) || inside((ml[1, 2], ml[2, 2]), r)) && return true
    for tl in lines(r)
        intersects(tl, l) && return true
    end
    return false
end


h(r::Rect) = ry(r) - ly(r)
w(r::Rect) = rx(r) - lx(r)
area(r::Rect) = h(r) * w(r)

perimeter(r::Rect) =  (s = h(r) + w(r); s + s)
to_plot_shape(r::Rect) = ([lx(r), rx(r), rx(r), lx(r)], [ly(r), ly(r), ry(r), ry(r)])

xsort(r1::Rect, r2::Rect, reverse=false) = sortr(r1, r2, reverse=reverse, axis=1)
ysort(r1::Rect, r2::Rect, reverse=false) = sortr(r1, r2, reverse=reverse, axis=2)

sortr(r1::Rect, r2::Rect; reverse=false, axis=1) =
    (!reverse && r1.m[axis, 1] > r2.m[axis, 1]) ? (r2, r1) : (r1, r2)

has_x_overlap(r1::Rect, r2::Rect) = has_overlap(r1::Rect, r2::Rect, axis=1)
has_y_overlap(r1::Rect, r2::Rect) = has_overlap(r1::Rect, r2::Rect, axis=2)

function has_overlap(r1::Rect, r2::Rect; axis=1)
    r1, r2 = sortr(r1, r2, reverse=false, axis=axis)
    return r1.m[axis, 1] <= r2.m[axis, 1] <= r1.m[axis, 2]
end

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
    projectY(r1::Rect, r2::Rect) -> (bottom, overlap, top)
```
Projects the rectangles along the Y-axis and returns three parts of rectangles.

`bottom`: The bottom segment of the projection
`overlap`: If there is any overlap between the rectangles
`top`: The top segment of the projection

Each portion is returned as a tuple.

If the rectangle is part of the first rectangle, it's returned as the first element of the
tuple. `nothing` is returned for a part when a portion is not available.
"""
projectY(r1::Rect, r2::Rect) = project(r1, r2, axis=2)

project(r1::Rect, r2::Rect; axis::Int=1) = project(promote(r1, r2)...; axis=axis)
function project(r1::Rect{T}, r2::Rect{T}; axis::Int=1) where T <: Number
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

    #High segment
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

"""
```
    visibleX(r1::Rect, r2::Rect) -> Rect
    visibleY(r1::Rect, r2::Rect) -> Rect
```
Projects the rectangles along the X-axis (Y-axis) and returns a rectangle area which is
completely visible from both rectangles.

`nothing` is returned when there is no overlap along the X-axis.
"""
visibleX(r1::Rect, r2::Rect) = visible(r1::Rect, r2::Rect, axis=1)
visibleY(r1::Rect, r2::Rect) = visible(r1::Rect, r2::Rect, axis=2)

visible(r1::Rect, r2::Rect; axis::Int=1) = visible(promote(r1, r2)...; axis=axis)

function visible(r1::Rect{T}, r2::Rect{T}; axis::Int=1) where T <: Number
    l, ox, r = project(r1, r2, axis=axis)
    ox == (nothing, nothing) && return nothing
    saxis = (axis == 1 ? 2 : 1)
    tr1, tr2 = sortr(ox[1], ox[2], axis=saxis)
    m = copy(tr1.m)
    m[saxis, 1] = tr1.m[saxis, 2]
    m[saxis, 2] + pcTol(T) > tr2.m[saxis, 1] &&
        return Line(lx(tr2), ly(tr2), lx(tr2), ry(tr2))
    m[saxis, 2] = tr2.m[saxis, 1]
    return Rect(m[1, 1], m[2, 1], m[1, 2], m[2, 2])
end

function get_overlapped_dist(l, h, f, a1, a2)
    # l = low and h = high
    lr, adl = l[1] === nothing ? (l[2], a2) : (notvoid(l[1]), a1)
    wlal    = lr   === nothing ? zero(a1)   : f(notvoid(lr))*area(notvoid(lr))

    hr, adh = h[1] === nothing ? (h[2], a2) : (notvoid(h[1]), a1)
    whah    = hr   === nothing ? zero(a1)   : f(notvoid(hr))*area(notvoid(hr))

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

"""
```
    min_dist(r1::Rect, r2::Rect) -> dx, dy
```
Minimum distance or gap between two rectangles.

`dx`: The distance in the x-direction
`dy`: The distance in the y-direction

The minimum distance will be `zero` when the rectangles are overlapping in a direction.
"""
function min_dist(r1::Rect{T}, r2::Rect{T}) where T <: Number
    r1, r2 = xsort(r1, r2)
    dx = has_x_overlap(r1, r2) ? zero(T) : lx(r2) - rx(r1)
    r1, r2 = ysort(r1, r2)
    dy = has_y_overlap(r1, r2) ? zero(T) : ly(r2) - ry(r1)
    return dx, dy
end
min_dist(r1::Rect, r2::Rect) = min_dist(promote(r1, r2)...)

mutable struct OrderedRectMap{T <: Number, V, D}
    data::IntervalMap{T, IntervalMap{T, V}}
    reverseMax::T
    function OrderedRectMap{T, V, D}(
        ;reverseMax::T1=zero(T)) where {T <: Number, V, D, T1 <: Number}
        @assert reverseMax >= zero(T) "Invalid max value for reverse ordering"
        new(IntervalMap{T, IntervalMap{T, V}}(), convert(T, reverseMax))
    end
end

const OrderedRectMapX{T, V} = OrderedRectMap{T, V, dir=1}
const OrderedRectMapY{T, V} = OrderedRectMap{T, V, dir=2}

function create_ordered_map(rects::AbstractVector{Rect{T}},
                            values::AbstractVector{V};
                            dir::Int=1,
                            reverseMax::T1=zero(T)) where {T <: Number, V, T1 <: Number}
    map = OrderedRectMap{T, V, dir}(reverseMax=reverseMax)
    itr = start(rects)
    itv = start(values)
    odir = dir == 1 ? 2 : 1
    while !done(rects, itr)
        (rect, itr) = next(rects,  itr)
        (v2,   itv) = next(values, itv)
        insert_rect!(map, rect, v2)
    end
    return map
end

function intersect(orm::OrderedRectMap{T1, V, D},
                   rect::Rect{T2}, dX::T1, dY::T1;
                   dirX=0, dirY=0) where {T1 <: Number, T2 <: Number, V, D}
    dl = dirX > 0  ? zero(T1) : -dX
    dr = dirX < 0  ? zero(T1) :  dX
    dd = dirY > 0  ? zero(T1) : -dY
    du = dirY < 0  ? zero(T1) :  dY

    r = convert(Rect{T1}, rect)

    while true 
        tr = Rect(lx(r) + dl, ly(r) + dd, rx(r) + dr, ry(r) + du)
        rs, vs = intersect(orm, tr)
        length(rs) == 0 && return rs, vs
        ttr = union(rs...)
        r == ttr && return rs, vs
        r = ttr
    end
end


function intersect(orm::OrderedRectMap{T1, V, D},
                   r::Rect{T2}) where {T1 <: Number, T2 <: Number, V, D}
    rect = convert(Rect{T1}, r)
    dir = D
    odir = dir == 1 ? 2 : 1
    r1 = coord(rect, dir)
    if orm.reverseMax != zero(T1)
        r1[1], r1[2] = (orm.reverseMax - r1[2]), (orm.reverseMax - r1[1])
    end
    r2 = coord(rect, odir)
    imv1 = intersect(orm.data, (r1[1], r1[2]))
    iv1 = start(imv1)
    retr = Vector{Rect{T1}}()
    retv = Vector{V}()
    while !done(imv1, iv1)
        v1, iv1 = next(imv1, iv1)
        imv2 = intersect(v1.value, (r2[1], r2[2]))
        iv2 = start(imv2)
        while !done(imv2, iv2)
            v2, iv2 = next(imv2, iv2)
            m = zeros(T1, (2,2))
            m[ dir, 1], m[ dir, 2] = (orm.reverseMax == zero(T1)) ?
                                     (v1.first, v1.last) :
                                     (orm.reverseMax - v1.last, orm.reverseMax - v1.first)
            m[odir, 1], m[odir, 2] = v2.first, v2.last
            push!(retr, Rect{T1}(m))
            push!(retv, v2.value)
        end
    end
    return retr, retv
end

function insert_rect!(orm::OrderedRectMap{T1, V, D},
    r::Rect{T2}, v::V) where {T1 <: Number, T2 <: Number, V, D}
    rect = convert(Rect{T1}, r)
    dir = D
    odir = dir == 1 ? 2 : 1
    r1 = coord(rect, dir)
    if orm.reverseMax != zero(T1)
        r1[1], r1[2] = (orm.reverseMax - r1[2]), (orm.reverseMax - r1[1])
    end
    r2 = coord(rect, odir)
    imv = get(orm.data, (r1[1], r1[2]), nothing)
    ret = nothing
    if imv != nothing
        ret = get(imv.value, (r2[1], r2[2]), nothing)
        imv.value[(r2[1], r2[2])] = v
    else
        imv = IntervalMap{T1, V}()
        imv[(r2[1], r2[2])] = v
        orm.data[(r1[1], r1[2])] = imv
    end
    return ret
end

function delete_rect!(orm::OrderedRectMap{T1, V, D},
    r::Rect{T2}) where {T1 <: Number, T2 <: Number, V, D}
    rect = convert(Rect{T1}, r)
    dir = D
    odir = dir == 1 ? 2 : 1
    r1 = coord(rect, dir)
    if orm.reverseMax != zero(T1)
        r1[1], r1[2] = (orm.reverseMax - r1[2]), (orm.reverseMax - r1[1])
    end
    r2 = coord(rect, odir)
    imv = get(orm.data, (r1[1], r1[2]), nothing)
    imv === nothing && return nothing
    ret = get(notvoid(imv).value, (r2[1], r2[2]), nothing)
    delete!(notvoid(imv).value, (r2[1], r2[2]))
    isempty(notvoid(imv).value) && delete!(orm.data, (r1[1], r1[2]))
    return ret === nothing ? ret : notvoid(ret).value
end
