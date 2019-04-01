struct Rect{T <: Number}
    lxv::T
    lyv::T
    rxv::T
    ryv::T
    function Rect{T}(m::Matrix{T}) where T <: Number
        @assert size(m) == (2, 2) "Invalid values"
        return Rect{T}(m[1, 1], m[2, 1], m[1, 2], m[2, 2])
    end

    Rect{T}(lxv::T, lyv::T, rxv::T, ryv::T) where T <: Number = 
        new{T}(min(lxv, rxv), min(lyv, ryv), max(lxv, rxv), max(lyv, ryv))

    Rect{T}(r::Rect) where T <: Number =
        Rect{T}(convert(T, r.lxv), convert(T, r.lyv),
                convert(T, r.rxv), convert(T, r.ryv))
end

matrix(r::Rect) = [r.lxv r.rxv; r.lyv r.ryv]
Rect(m::Matrix{T}) where T <: Number = Rect{T}(m)

function Rect(lx::Number, ly::Number, rx::Number, ry::Number)
    t = promote(lx, ly, rx, ry)
    return Rect{eltype(t)}(t...)
end

Base.convert(::Type{Rect{T}}, r::Rect{S}) where {T <: Number, S <: Number} = 
    T === S ? r : Rect{T}(r)

Base.promote_rule(::Type{Rect{T}},
                  ::Type{Rect{S}}) where {T <: Number, S <: Number} =
    Rect{promote_type(T, S)}

Base.show(io::IO, r::Rect) =
    print(io, "Rect:[$(lx(r)) $(ly(r)) $(rx(r)) $(ry(r))]")

lb(r) = (r.lxv, r.lyv)
ru(r) = (r.rxv, r.ryv)
lx(r) = r.lxv
ly(r) = r.lyv
rx(r) = r.rxv
ry(r) = r.ryv

xplot(r::Rect{T}) where T = T[lx(r), rx(r), rx(r), lx(r)]
yplot(r::Rect{T}) where T = T[lx(r), lx(r), rx(r), rx(r)]

coord(r, axis) = axis == 1 ? (r.lxv, r.rxv) : (r.lyv, r.ryv)
x(r) = coord(r, 1)
y(r) = coord(r, 2)
c_lo(r, axis)   = axis == 1 ? r.lxv : r.lyv
c_hi(r, axis)   = axis == 1 ? r.rxv : r.ryv

hlines(r::Rect) =
    [Line(lx(r), ly(r), rx(r), ly(r)), Line(lx(r), ry(r), rx(r), ry(r))]
vlines(r::Rect) =
    [Line(lx(r), ly(r), lx(r), ry(r)), Line(rx(r), ly(r), rx(r), ry(r))]
lines(r::Rect) = append!(hlines(r), vlines(r))
olines(r::Rect) =
    (ls = lines(r); [ls[1], ls[4], reverse(ls[2]), reverse(ls[3])])
diags(r::Rect)  =
    [Line(lx(r), ly(r), rx(r), ry(r)), Line(rx(r), ly(r), lx(r), ry(r))]
cg(r::Rect) = div(diags(r)[1], 1//2)

Base.union(r1::Rect, r2::Rect) = 
    Rect(min(lx(r1), lx(r2)), min(ly(r1), ly(r2)),
         max(rx(r1), rx(r2)), max(ry(r1), ry(r2)))

Base.union(r1::Rect, r2::Rect, y::Rect...) = Base.union(r1, union(r2, y...))
Base.union(r::Rect) = r
function Base.union(rs::AbstractVector{Rect{T}}) where T
    lxv, lyv, rxv, ryv = typemax(T), typemax(T), typemin(T), typemin(T)
    for r in rs
        lxv > lx(r) && (lxv = lx(r))
        lyv > ly(r) && (lyv = ly(r))
        rxv < rx(r) && (rxv = rx(r))
        ryv < ry(r) && (ryv = ry(r))
    end
    return Rect(lxv, lyv, rxv, ryv)
end

Base.intersect(r1::Rect, r2::Rect) = intersect(promote(r1, r2)...)

function Base.intersect(r1::Rect{T}, r2::Rect{T}) where T <: Number
    l = max.(lb(r1), lb(r2))
    r = min.(ru(r1), ru(r2))
    l1 = l .+ pcTol(T)
    any(l1 .>= r) && return nothing
    return Rect(l[1], l[2], r[1], r[2])
end

Base.:(==)(r1::Rect{T}, r2::Rect{T}) where {T <: Number} =
    abs(r1.lxv - r2.lxv) <= pcTol(T) &&
    abs(r1.lyv - r2.lyv) <= pcTol(T) &&
    abs(r1.rxv - r2.rxv) <= pcTol(T) &&
    abs(r1.ryv - r2.ryv) <= pcTol(T) 
Base.:(==)(r1::Rect, r2::Rect) = ==(promote(r1, r2)...)

inside(p::Tuple{T, T}, r::Rect{T}) where T <: Number =
    r.lxv <= p[1] <= r.rxv && r.lyv <= p[2] <= r.ryv

function inside(p::Tuple{T1, T2}, r::Rect{S}) where {T1 <: Number,
                                                     T2 <: Number,
                                                     S  <: Number}
    ST = promote_type(S, T1, T2)
    inside(convert(Tuple{ST, ST}, p), convert(Rect{ST}, r))
end

inside(ri::Rect, ro::Rect) = intersect(ri, ro) == ri

intersects(r1::Rect, r2::Rect) = intersect(r1, r2) !== nothing

function intersects(r::Rect, l::Line)
    (inside((sx(l), sy(l)), r) || inside((ex(l), ey(l)), r)) &&
        return true
    for tl in lines(r)
        intersects(tl, l) && return true
    end
    return false
end

h(r::Rect) = ry(r) - ly(r)
w(r::Rect) = rx(r) - lx(r)
area(r::Rect) = h(r) * w(r)

perimeter(r::Rect) =  (s = h(r) + w(r); s + s)
to_plot_shape(r::Rect) =
    ([lx(r), rx(r), rx(r), lx(r)], [ly(r), ly(r), ry(r), ry(r)])

xsort(r1::Rect, r2::Rect, reverse=false) =
    sortr(r1, r2, reverse=reverse, axis=1)
ysort(r1::Rect, r2::Rect, reverse=false) =
    sortr(r1, r2, reverse=reverse, axis=2)

sortr(r1::Rect, r2::Rect; reverse=false, axis=1) =
    (!reverse && c_lo(r1, axis) > c_lo(r2, axis)) ? (r2, r1) : (r1, r2)

has_x_overlap(r1::Rect, r2::Rect; isopen=false) =
    has_overlap(r1::Rect, r2::Rect, axis=1, isopen=isopen)
has_y_overlap(r1::Rect, r2::Rect; isopen=false) =
    has_overlap(r1::Rect, r2::Rect, axis=2, isopen=isopen)

function has_overlap(ri1::Rect{T1}, ri2::Rect{T2};
                     axis=1, isopen=false) where {T1, T2}
    r1, r2 = promote(ri1, ri2)
    T = typeof(r1.lxv)
    tol = isopen ? pcTol(T) : zero(T)
    rt = axis == 1 ? Rect(lx(r1) + tol, ly(r1), rx(r1) - tol, ry(r1)) :
                     Rect(lx(r1), ly(r1) + tol, rx(r1), ry(r1) - tol)
    r1, r2 = sortr(rt, r2, reverse=false, axis=axis)
    return c_lo(r1, axis) <= c_lo(r2, axis) <= c_hi(r1, axis)
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

If the rectangle is part of the first rectangle, it's returned as the first
element of the tuple. `nothing` is returned for a part when a portion is not
available.
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

If the rectangle is part of the first rectangle, it's returned as the first
element of the tuple. `nothing` is returned for a part when a portion is not
available.
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
        l = axis == 1 ? Rect{T}(axl[1], ly(lr), axl[2], ry(lr)) :
                        Rect{T}(lx(lr), axl[1], rx(lr), axl[2])
        low = !flip ? (l, nothing) : (nothing, l)
        # Non-overlap
        l == lr &&
            return low, (nothing, nothing), !flip ? (nothing, hr) : (hr, nothing)
    else
        low = nothing, nothing
    end

    #Overlap segment
    om1, om2 = matrix(r1), matrix(r2)
    om1[axis, 1] = om2[axis, 1] = axl[2]
    om1[axis, 2] = om2[axis, 2] = axl[3]

    overlap = Rect{T}(om1), Rect{T}(om2)

    #High segment
    if -pcTol(T) <= c_hi(r1, axis) - c_hi(r2, axis) <= pcTol(T)
        high = nothing, nothing
    else
        hm = c_hi(r1, axis) > c_hi(r2, axis) ? matrix(r1) : matrix(r2)
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
Projects the rectangles along the X-axis (Y-axis) and returns a rectangle area
which is completely visible from both rectangles.

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
    m = matrix(tr1)
    m[saxis, 1] = c_hi(tr1, saxis)
    m[saxis, 2] + pcTol(T) > c_lo(tr2, saxis) &&
        return Line(lx(tr2), ly(tr2), lx(tr2), ry(tr2))
    m[saxis, 2] = c_lo(tr2, saxis)
    return Rect(m)
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
Rectangles are essentially point sets. Hence, one can perceive existence of a
minimum distance of one point in `r1` from `r2`. Similar, distance would also
exist for every point in `r2` from `r1`. While, technically Euclidean distance
metric can exist, the computation is fairly cumborsome. Here, we use the city
block distance or L1-metric.

`dx`: The distance in the x-direction
`dy`: The distance in the y-direction

The minimum distance will be `zero` when the rectangles are intersecting.
The distance also will be lower in a specific direction if there is an overlap of
 the rectangles in that direction
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
    ox != (nothing, nothing) &&
        return get_overlapped_dist(l, r, w, a1, a2), dy
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

The minimum distance will be `zero` when the rectangles are overlapping in a
direction.
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
    data::IntervalTree{T, IntervalTree{T, V}}
    reverseMax::T
    function OrderedRectMap{T, V, D}(
        ;reverseMax::T1=zero(T)) where {T <: Number, V, D, T1 <: Number}
        @assert reverseMax >= zero(T) "Invalid max value for reverse ordering"
        new(IntervalTree{T, IntervalTree{T, V}}(), convert(T, reverseMax))
    end
end

const OrderedRectMapX{T, V} = OrderedRectMap{T, V, 1}
const OrderedRectMapY{T, V} = OrderedRectMap{T, V, 2}

function create_ordered_map(rects::AbstractVector{Rect{T}},
                            values::AbstractVector{V};
                            dir::Int=1,
                            reverseMax::T1=zero(T)) where {T <: Number,
                                                           V,
                                                           T1 <: Number}
    map = OrderedRectMap{T, V, dir}(reverseMax=reverseMax)
    nr = iterate(rects)
    nv = iterate(values)
    odir = dir == 1 ? 2 : 1
    while nr !== nothing
        rect, itr = nr
        v2,   itv = nv
        nr = iterate(rects, itr)
        nv = iterate(values, itv)
        insert_rect!(map, rect, v2)
    end
    return map
end

function Base.intersect(orm::OrderedRectMap{T1, V, D},
                        rect::Rect{T2}, dX::T1, dY::T1;
                        dirX=0, dirY=0,
                        fstop::Function=(x) -> false) where {T1 <: Number,
                                                             T2 <: Number, V, D}
    dl = dirX > 0  ? zero(T1) : -dX
    dr = dirX < 0  ? zero(T1) :  dX
    dd = dirY > 0  ? zero(T1) : -dY
    du = dirY < 0  ? zero(T1) :  dY

    r = convert(Rect{T1}, rect)
    ors, ovs = Vector{Rect{T1}}(), Vector{V}()
    while true 
        tr = Rect(lx(r) + dl, ly(r) + dd, rx(r) + dr, ry(r) + du)
        rs, vs = intersect(orm, tr)
        length(rs) == 0 && return rs, vs
        ttr = union(rs)
        fstop(ttr) && return ors, ovs
        r == ttr && return rs, vs
        r, ors, ovs = ttr, rs, vs
    end
end


function Base.intersect(orm::OrderedRectMap{T1, V, D},
                        r::Rect{T2};
                        isopen = true) where {T1 <: Number, T2 <: Number, V, D}
    rect = convert(Rect{T1}, r)
    dir = D
    odir = dir == 1 ? 2 : 1
    minv1, maxv1 = coord(rect, dir)
    if orm.reverseMax != zero(T1)
        minv1, maxv1 = (orm.reverseMax - maxv1), (orm.reverseMax - minv1)
    end
    minv2, maxv2 = coord(rect, odir)
    tol = isopen ? pcTol(T1) : zero(T1)
    imv1 = intersect(orm.data, Interval(minv1 + tol, maxv1 - tol))
    retr = Vector{Rect{T1}}()
    retv = Vector{V}()
    nimv1 = iterate(imv1)
    while nimv1 !== nothing
        v1, iv1 = nimv1
        imv2 = intersect(v1[2], Interval(minv2 + tol, maxv2 - tol))
        nimv2 = iterate(imv2)
        while nimv2 !== nothing
            v2, iv2 = nimv2
            m = zeros(T1, (2,2))
            m[ dir, 1], m[ dir, 2] =
                (orm.reverseMax == zero(T1)) ? (v1[1].lo, v1[1].hi) :
                (orm.reverseMax - v1[1].hi, orm.reverseMax - v1[1].lo)
            m[odir, 1], m[odir, 2] = v2[1].lo, v2[1].hi
            push!(retr, Rect{T1}(m))
            push!(retv, v2[2])
            nimv2 = iterate(imv2, iv2)
        end
        nimv1 = iterate(imv1, iv1)
    end
    return retr, retv
end

function insert_rect!(orm::OrderedRectMap{T1, V, D},
    r::Rect{T2}, v::V) where {T1 <: Number, T2 <: Number, V, D}
    rect = convert(Rect{T1}, r)
    dir = D
    odir = dir == 1 ? 2 : 1
    minv1, maxv1 = coord(rect, dir)
    if orm.reverseMax != zero(T1)
        minv1, maxv1 = (orm.reverseMax - maxv1), (orm.reverseMax - minv1)
    end
    imv = get!(orm.data, Interval(minv1, maxv1), IntervalTree{T1, V}())
    minv2, maxv2 = coord(rect, odir)
    itv2 = Interval(minv2, maxv2)
    tv = get!(imv, itv2, v)
    tv === v && return nothing
    tv = delete!(imv, itv2)
    imv[itv2] = v
    return tv
end

function delete_rect!(orm::OrderedRectMap{T1, V, D},
    r::Rect{T2}) where {T1 <: Number, T2 <: Number, V, D}
    rect = convert(Rect{T1}, r)
    dir = D
    odir = dir == 1 ? 2 : 1
    minv1, maxv1 = coord(rect, dir)
    if orm.reverseMax != zero(T1)
        minv1, maxv1 = (orm.reverseMax - maxv1), (orm.reverseMax - minv1)
    end
    itv1 = Interval(minv1, maxv1)
    imv = get(orm.data, itv1, IntervalTree{T1, V}())
    isempty(imv) && return nothing
    minv2, maxv2 = coord(rect, odir)
    ret = delete!(imv, Interval(minv2, maxv2))
    isempty(imv) && delete!(orm.data, itv1)
    return ret === nothing ? ret : ret[2]
end

function line_xsection(rect::Rect{T1}, ls::Vector{Line{T2}},
                       flines::Function, flt::Function,
                       o::Tuple{Int, Int}) where {T1 <: Number, T2 <: Number}
    r = convert(Rect{T2}, rect)
    l = flines(r)
    xlines = Vector{Int}()
    minv = searchsortedfirst(ls, l[o[1]], lt=flt)
    maxv = searchsortedlast(ls,  l[o[2]], lt=flt)
    for k = minv:maxv
        !intersects(r, ls[k]) && continue
        push!(xlines, k)
    end
    return xlines
end

"""
    Given a Rectangle and a set of already sorted set of vertical lines ordered
    left to right, provides the indices that intersect the rectangle.
"""
vline_xsection(r::Rect{T1}, vls::Vector{Line{T2}}) where {T1 <: Number,
                                                          T2 <: Number} = 
    line_xsection(r, vls, vlines, vert_asc, (1, 2))

"""
    Given a Rectangle and a set of a sorted set of horizontal lines ordered
    top to bottom, provides the indices that intersect the rectangle.
"""
hline_xsection(r::Rect{T1}, hls::Vector{Line{T2}}) where {T1 <: Number,
                                                          T2 <: Number} = 
    line_xsection(r, hls, hlines, horiz_desc, (2, 1))
