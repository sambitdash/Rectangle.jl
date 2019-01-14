using "abstractnode.jl"

mutable struct BSTNode{K, V} <: AbstractNode{K, V}
    k::K
    v::V
    l::BSTNode{K, V}
    r::BSTNode{K, V}
    p::BSTNode{K, V}
    function BSTNode{K, V}() where {K, V}
        self = new{K, V}()
        self.l = self.r = self.p = self
    end
end

mutable struct BinarySearchTree{K, V} <: AbstractBST{K, V}
    root::BSTNode{K, V}
    nil::BSTNode{K, V}
    n::Int
    unique::Bool
    function BinarySearchTree{K, V}() where {K, V}
        s = new{K, V}()
        nil = BSTNode{K, V}()
        @assert nil.l === nil && nil.r === nil && nil.p === nil
        s.n = 0
        s.unique = false
        s.root = s.nil = nil
        return s
    end
end

function BSTNode(t::BinarySearchTree{K, V}, k::K, v::V) where {K, V}
    s = BSTNode{K, V}()
    s.k, s.v, s.l, s.r, s.p = k, v, t.nil, t.nil, t.nil
    return s
end


isnil(t::BinarySearchTree, n::BSTNode) = n === t.nil
Base.empty!(t::BinarySearchTree) = ((t.root, t.n) = (t.nil, 0))

function Base.insert!(t::BinarySearchTree, k::K, v::V) where {K, V}
    t.root = t.n == 0 ? BSTNode(t, k, v) : _insert!(t, t.root, k, v, t.unique)
    t.n += 1
    return
end

@inline function Base.get(t::BinarySearchTree{K, V}, k::K, v::V) where {K, V}
    isempty(t) && return v
    n, d = _search(t, t.root, k)
    d != 0 && return v
    return n.v
end

@inline function _insert!(t::BinarySearchTree,
                          n::BSTNode{K, V},
                          k::K, v::V,
                          unique::Bool=true) where {K, V}
    tn = ni = n
    left = true
    while !isnil(t, tn)
        ni = tn
        tn = k < ni.k ? ni.l : (!unique || (ni.k < k)) ? ni.r :
            unique && error("Key $k already exists.")
    end
    nn = BSTNode(t, k, v)
    if k < ni.k
        _l!(t, ni, nn)
    else
        _r!(t, ni, nn)
    end
    return n
end

@inline function  _transplant!(t::BinarySearchTree, u::BSTNode, v::BSTNode)
    if isnil(t, u.p)
        t.root = v
    elseif u === u.p.l
        u.p.l = v
    else
        u.p.r = v
    end
    v.p = u.p
end

function _delete!(t::BinarySearchTree, z::BSTNode)
    if isnil(t, z.l)
        _transplant!(t, z, z.r)
    elseif isnil(t, z.r)
        _transplant!(t, z, z.l)
    else
        y = _minimum(z.r, t)
        if y.p !== z
            _transplant!(t, y, y.r)
            y.r = z.r
            y.r.p = y
        end
        _transplant!(t, z, y)
        y.l = z.l
        y.l.p = y
    end
    return z
end
