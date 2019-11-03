import Base: pairs

mutable struct BinaryNode{K, V} <: AbstractNode{K, V}
    k::K
    v::V
    l::BinaryNode{K, V}
    r::BinaryNode{K, V}
    p::BinaryNode{K, V}
    function BinaryNode{K, V}() where {K, V}
        self = new{K, V}()
        self.l = self.r = self.p = n= self
        return self
    end
end

function divide_and_conquer(pred::Function, nil::BinaryNode{K, V}) where {K, V}
    predl, predr, k, v = pred()
    predl === nothing && predr === nothing && return (nil, 0)
    node = BinaryNode{K, V}()
    (node.k, node.v) = (k, v)
    node.l, cl = predl === nothing ? (nil, 0) : divide_and_conquer(predl, nil)
    node.r, cr = predr === nothing ? (nil, 0) : divide_and_conquer(predr, nil)
    node.l.p = node.r.p = node
    return node, cl + cr + 1
end

mutable struct BinaryTree{K, V} <: AbstractBinaryTree{K, V}
    nil::BinaryNode{K, V}
    root::BinaryNode{K, V}
    n::Int
    function BinaryTree{K, V}(pred::Function) where {K, V}
        nil = BinaryNode{K, V}()
        root, n = divide_and_conquer(pred, nil)
        return new(nil, root, n)
    end
end

Rectangle.isnil(t::BinaryTree, node::BinaryNode) = node === t.nil

function Base.pairs(t::BinaryTree{K, V}) where {K, V}
    ps = Vector{Tuple{K, V}}(undef, length(t))
    i = 0
    _inorder(t.root, t) do n
        ps[i+=1] = (n.k, n.v)
        return true
    end
    return ps
end

function Base.keys(t::BinaryTree{K, V}) where {K, V}
    ks = Vector{K}(undef, length(t))
    i = 0
    _inorder(t.root, t) do n
        ps[i+=1] = n.k
        return true
    end
    return ps
end

function Base.values(t::BinaryTree{K, V}) where {K, V}
    ks = Vector{V}(undef, length(t))
    i = 0
    _inorder(t.root, t) do n
        ps[i+=1] = n.v
        return true
    end
    return ps
end

struct XYData{T}
    dir::Int
    loc::T
    range::Tuple{T, T}
end

@inline function Line(xy::XYData{T}) where T
    dir, r1, r2, l = xy.dir, xy.range..., xy.loc
    return dir == 1 ? Line(r1, l, r2, l) : Line(l, r1, l, r2)
end

const XYNode{T, V} = BinaryNode{XYData{T}, V}
const XYTree{T, V} = BinaryTree{XYData{T}, V}

function get_values(t::XYTree{K, V}) where {K, V}
    lines, vs = Vector{Line{K}}(undef, length(t)), Vector{V}(undef, length(t))
    ps = pairs(t)
    for i = firstindex(ps):lastindex(ps)
        lines[i], vs[i] = Line(ps[i][1]), ps[i][2]
    end
    return lines, vs
end
