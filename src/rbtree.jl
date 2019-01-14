#=
CLRS 3rd Ed. Chapter 13

1. Every node is either red or black.
2. The root is black.
3. Every leaf (NIL ) is black.
4. If a node is red, then both its children are black.
5. For each node, all simple paths from the node to descendant leaves contain the
same number of black nodes.

=#

import Rectangle.AbstractNode

mutable struct RBNode{K, V} <: AbstractNode{K, V}
    k::K
    v::V
    red::Bool
    l::RBNode{K, V}
    r::RBNode{K, V}
    p::RBNode{K, V}
    function RBNode{K, V}() where {K, V}
        self = new{K, V}()
        self.red = false
        self.l = self.r = self.p = self
    end
end

mutable struct RBTree{K, V} <: AbstractBST{K, V}
    root::RBNode{K, V}
    nil::RBNode{K, V}
    n::Int
    unique::Bool
    function RBTree{K, V}() where {K, V}
        s = new{K, V}()
        nil = RBNode{K, V}()
        @assert nil.l === nil && nil.r === nil && nil.p === nil
        s.n = 0
        s.unique = false
        s.root = s.nil = nil
        return s
    end
end

function RBNode(t::RBTree{K, V}, k::K, v::V) where {K, V}
    s = RBNode{K, V}()
    s.k, s.v, s.red, s.l, s.r, s.p = k, v, false, t.nil, t.nil, t.nil
    return s
end

function Base.show(io::IO, t::AbstractBST)
    println(io, "$(typeof(t)) Tree with $(t.n) nodes.")
    !isnil(t, t.root) && println(io, "Root at: $(t.root.k).")
end

isnil(t::RBTree, n::RBNode) = n === t.nil
Base.empty!(t::RBTree) = (t.root = t.nil; t.n = 0; nothing)

function Base.insert!(t::RBTree{K, V}, k::K, v::V) where {K, V}
    z = RBNode(t, k, v)
    y::RBNode{K, V} = t.nil
    x::RBNode{K, V} = t.root

    while x !== t.nil
        y = x
        x = k < x.k ? x.l :
            !t.unique || (x.k < k) ? x.r :
            t.unique && error("Key $k already exists.")
    end
    z.p = y
    if y === t.nil
        t.root = z
    elseif k < y.k
        y.l = z
    else
        y.r = z
    end
    z.red = true
    _insert_fixup!(t, z)
    t.n += 1
    return t
end

@inline function _insert_fixup!(t::RBTree, z::RBNode)
    while z.p.red
        if z.p === z.p.p.l
            y = z.p.p.r
            if y.red
                z.p.red = false
                y.red = false
                z.p.p.red = true
                z = z.p.p
            else
                if z === z.p.r
                    z = z.p
                    left_rotate!(t, z)
                end
                z.p.red = false
                z.p.p.red = true
                right_rotate!(t, z.p.p)
            end
        else
            y = z.p.p.l
            if y.red
                z.p.red = false
                y.red = false
                z.p.p.red = true
                z = z.p.p
            else
                if z === z.p.l
                    z = z.p
                    right_rotate!(t, z)
                end
                z.p.red = false
                z.p.p.red = true
                left_rotate!(t, z.p.p)
            end
        end
    end
    t.root.red = false
end

# Intermediate step used in delete!

@inline function  _transplant!(t::RBTree, u::RBNode, v::RBNode)
    if u.p === t.nil
        t.root = v
    elseif u === u.p.l
        u.p.l = v
    else
        u.p.r = v
    end
    v.p = u.p
end

@inline function _delete!(t::RBTree, z::RBNode)
    y = z
    y_is_red = y.red
    if z.l === t.nil
        x = z.r
        _transplant!(t, z, z.r)
    elseif z.r === t.nil
        x = z.l
        _transplant!(t, z, z.l)
    else
        y = _minimum(z.r, t)
        y_is_red = y.red
        x = y.r
        if y.p === z
            x.p = y
        else
            _transplant!(t, y, y.r)
            y.r = z.r
            y.r.p = y
        end
        _transplant!(t, z, y)
        y.l = z.l
        y.l.p = y
        y.red = z.red
    end
    if !y_is_red
        _delete_fixup!(t, x)
    end
    return z
end

function _delete_fixup!(t::RBTree, x::RBNode)
    while x !== t.root && !x.red
        if x === x.p.l
            w = x.p.r
            if w.red
                w.red = false
                x.p.red = true
                left_rotate!(t, x.p)
                w = x.p.r
            end
            if !w.l.red && !w.r.red
                w.red = true
                x = x.p
            else
                if !w.r.red
                    w.l.red = false
                    w.red = true
                    right_rotate!(t, w)
                    w = x.p.r
                end
                w.red = x.p.red
                x.p.red = false
                w.r.red = false
                left_rotate!(t, x.p)
                x = t.root
            end
        else
            w = x.p.l
            if w.red
                w.red = false
                x.p.red = true
                right_rotate!(t, x.p)
                w = x.p.l
            end
            if !w.l.red && !w.r.red
                w.red = true
                x = x.p
            else
                if !w.l.red
                    w.r.red = false
                    w.red = true
                    left_rotate!(t, w)
                    w = x.p.l
                end
                w.red = x.p.red
                x.p.red = false
                w.l.red = false
                right_rotate!(t, x.p)
                x = t.root
            end
        end
    end
    x.red = false
end
