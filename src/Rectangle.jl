__precompile__()

module Rectangle

export  Rect,
            union,
            intersect,
            inside

import Base: ==, union, intersect

struct Rect{T <: Number}
    lx::T
    ly::T
    rx::T
    ry::T
    function Rect{T}(lx::T, ly::T, rx::T, ry::T) where {T <: Number}
        @assert lx <= rx && ly <= ry "Invalid values."
        return new(lx, ly, rx, ry)
    end
end

Rect(lx::T, ly::T, rx::T, ry::T) where {T <: Number} = Rect{T}(lx, ly, rx, ry)

function union(r1::Rect, r2::Rect)
    lx = min(r1.lx, r2.lx)
    ly = min(r1.ly, r2.ly)
    rx = max(r1.rx, r2.rx)
    ry = max(r1.ry, r2.ry)
    return Rect(lx, ly, rx, ry)
end

function intersect(r1::Rect{T}, r2::Rect{T}) where T <: Number
    lx = max(r1.lx, r2.lx)
    ly = max(r1.ly, r2.ly)
    rx = min(r1.rx, r2.rx)
    ry = min(r1.ry, r2.ry)
    (lx > rx || ly > ry) && return nothing
    return Rect(lx, ly, rx, ry)
end

pcTol(::Type{T}) where {T <: Integer} = zero(T)
pcTol(::Type{T}) where {T <: Rational} = zero(T)
pcTol(::Type{T}) where {T <: Number}  = T(0.000001)

function ==(r1::Rect{T}, r2::Rect{T}) where {T <: Number}
    dlx = abs(r1.lx - r2.lx)
    dly = abs(r1.ly - r2.ly)
    drx = abs(r1.rx - r2.rx)
    dry = abs(r1.ry - r2.ry)
    return dlx <= pcTol(T) && dly <= pcTol(T) && drx <= pcTol(T) && dry <= pcTol(T)
end

inside(p::Tuple{T, T}, r::Rect{T}) where T <: Number =
    r.lx <= p[1] <= r.rx && r.ly <= p[2] <= r.ry

inside(ri::Rect, ro::Rect) = intersect(ri, ro) == ri

end # module
