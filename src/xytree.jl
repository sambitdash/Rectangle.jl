mutable struct XYNode{K, V} <: AbstractNode{K, V}
    dir::Int
    loc::K
    range::Tuple{K, K}
    v::V
    l::XYNode{K, V}
    r::XYNode{K, V}
    p::XYNode{K, V}
    function XYNode{K, V}() where {K, V}
        self = new{K, V}()
        self.l = self.r = self.p = n= self
        return self
    end
end

function build_xy_node(pred::Function, nil::XYNode{K, V}) where {K, V}
    predl, predr, (dir, loc, range, v) = pred()
    predl === nothing && predr === nothing && return (nil, 0)
    node = XYNode{K, V}()
    node.dir, node.loc, node.range, node.v = dir, loc, range, v
    node.l, cl = predl === nothing ? (nil, 0) : build_xy_node(predl, nil)
    node.r, cr = predr === nothing ? (nil, 0) : build_xy_node(predr, nil)
    node.l.p = node
    node.r.p = node
    return node, cl + cr + 1
end

mutable struct XYTree{K, V} <: AbstractBinaryTree{K, V}
    nil::XYNode{K, V}
    root::XYNode{K, V}
    n::Int
    function XYTree{K, V}(pred::Function) where {K, V}
        nil = XYNode{K, V}()
        root, n = build_xy_node(pred, nil)
        return new(nil, root, n)
    end
end

Rectangle.isnil(t::XYTree, n::XYNode) = n === t.nil

function get_values(t::XYTree{K, V}) where {K, V}
    lines, vs = Vector{Line{K}}(undef, length(t)), Vector{V}(undef, length(t))
    i = 0
    _inorder(t.root, t) do n
        dir, r1, r2, l = n.dir, n.range..., n.loc
        l = dir == 1 ? Line(r1, l, r2, l) : Line(l, r1, l, r2)
        i += 1
        lines[i], vs[i] = l, n.v
        return true
    end
    return lines, vs
end
