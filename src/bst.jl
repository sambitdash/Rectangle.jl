# Most algorithms are written keeping the concepts and pseudo code of
# CLRS 3ed as close to as in the book. There has been minor deviations
# taken at places for programming and architectural reasons. 


# These data structures assumes strong trichotomy of keys exist
# k1 and k2 if are valid keys then one of the following relationship
# has to be true.
# 1. k1  < k2
# 2. k1 == k2
# 3. k1  > k2
#
# However, to the user of these data structures have to implement
# `Base.isless` only.
# No other operators are used in the code so that there are no implicit
# overheads due to fallback options. 

abstract type AbstractNode{K, V} end
abstract type AbstractBST{K, V} end

Base.isless(n1::T, n2::T) where {T <:AbstractNode} = Base.isless(n1.k, n2.k)
Base.isless(n::AbstractNode{K, V}, k::K) where {K, V} = isless(n.k, k)
Base.isless(k::K, n::AbstractNode{K, V}) where {K, V} = isless(k, n.k)

_k(n::AbstractNode) = n.k
_v(n::AbstractNode) = n.v
_l(n::AbstractNode) = n.l
_r(n::AbstractNode) = n.r
_p(n::AbstractNode) = n.p
_l!(t::T, x::N, y::N) where {K, V,
                             N <: AbstractNode{K, V},
                             T <: AbstractBST{K, V}} =
                                 ((x.l, y.p) = (y, (isnil(t, y) ? y.p : x)))
_r!(t::T, x::N, y::N) where {K, V,
                             N <: AbstractNode{K, V},
                             T <: AbstractBST{K, V}} =
                                 ((x.r, y.p) = (y, (isnil(t, y) ? y.p : x)))
_p!(x::T, y::T) where {T <: AbstractNode} = (x.p = y)


@inline function _extremum(dir::Function, n::AbstractNode, t::AbstractBST)
    while true
        nn = dir(n)
        isnil(t, nn) && return n
        n = nn
    end
end

_maximum(n::AbstractNode, t::AbstractBST) = _extremum(_r, n, t)
_minimum(n::AbstractNode, t::AbstractBST) = _extremum(_l, n, t)

_successor(x::AbstractNode, t::AbstractBST)   = _pred_succ(_r, _minimum, x, t)
_predecessor(x::AbstractNode, t::AbstractBST) = _pred_succ(_l, _maximum, x, t)

@inline function _pred_succ(f::Function, g::Function,
                            x::AbstractNode, t::AbstractBST)
    !isnil(t, f(x)) && return g(f(x), t)
    y = _p(x)
    while !isnil(t, y) && x === f(y)
        x = y
        y = _p(y)
    end
    return y
end

function _inorder(f::Function, n::AbstractNode, t::AbstractBST)
    if !isnil(t, n)
        proceed = true
        proceed = (proceed && _inorder(f, n.l, t))
        res = f(n)
        if res isa Bool
            proceed = (proceed && res)
        end
        proceed = (proceed && _inorder(f, n.r, t))
        return proceed
    else
        return true
    end
end

function node_print(t::AbstractBST{K, V},
                    n::AbstractNode{K, V},
                    prefix::String,
                    left::Bool) where {K, V}
    isnil(t, n) && return
    prefix *= prefix
    node_print(t, n.l, prefix, true)
    RED="\033[0;31m"
    NC="\033[0m"
    if n.red
        println(prefix, RED, n.k, NC)
    else
        println(prefix, n.k)
    end
    node_print(t, n.r, prefix, false)
end

@inline function _search(t::AbstractBST, n::AbstractNode{K, V}, k::K) where {K, V}
    while true
        if k < _k(n)
            nn = _l(n)
            d  = -1
        elseif _k(n) < k
            nn = _r(n)
            d = 1
        else
            return (n, 0)
        end
        isnil(t, nn) && return n, d
        n = nn
    end
end

Base.length(t::AbstractBST) = t.n
Base.isempty(t::AbstractBST) = Base.length(t) == 0

function Base.maximum(t::AbstractBST)
    isempty(t) && error("Empty tree cannot have a maximum")
    n = _maximum(t.root, t)
    return n.k => n.v
end

function Base.minimum(t::AbstractBST)
    isempty(t) && error("Empty tree cannot have a minimum")
    n = _minimum(t.root, t)
    return n.k => n.v
end

@inline function left_rotate!(t::T,
                              x::N) where {T <: AbstractBST, N <: AbstractNode}
    y = x.r
    x.r = y.l
    !isnil(t, y.l) && (y.l.p = x)
    y.p = x.p
    if isnil(t, x.p)
        t.root = y
    elseif x === x.p.l
        x.p.l = y
    else
        x.p.r = y
    end
    y.l = x
    x.p = y
    return 
end

@inline function right_rotate!(t::T,
                               y::N) where {T <: AbstractBST, N <: AbstractNode}
    x = y.l
    y.l = x.r
    !isnil(t, x.r) && (x.r.p = y)
    x.p = y.p
    if isnil(t, y.p)
        t.root = x
    elseif y === y.p.r
        y.p.r = x
    else
        y.p.l = x
    end
    x.r = y
    y.p = x
    return 
end

@inline function Base.delete!(t::AbstractBST{K, V}, k::K) where {K, V}
    isempty(t) && error("Cannot delete from empty tree")
    n, d = _search(t, t.root, k)
    if d == 0
        _delete!(t, n)
        return n.k => n.v
    else
        return nothing
    end
end

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

@inline function Base.get(t::AbstractBST{K, V}, k::K, v::V) where {K, V}
    isempty(t) && return v
    n, d = _search(t, t.root, k)
    d != 0 && return v
    return n.v
end

@inline function Base.get!(t::AbstractBST{K, V}, k::K, v::V) where {K, V}
    if isempty(t)
        insert!(t, k, v)
        return v
    end
    n, d = _search(t, t.root, k)
    if d != 0
        insert!(t, k, v)
        return v
    end
    return n.v
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

@inline function _insert!(t::BinarySearchTree,
                          n::BSTNode{K, V},
                          k::K, v::V,
                          unique::Bool=true) where {K, V}
    tn = ni = n
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
    t.n -= 1
    return z
end

#=
CLRS 3rd Ed. Chapter 13

1. Every node is either red or black.
2. The root is black.
3. Every leaf (NIL ) is black.
4. If a node is red, then both its children are black.
5. For each node, all simple paths from the node to descendant leaves contain the
same number of black nodes.

=#

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
    println(io, "$(typeof(t)) Tree with $(length(t)) nodes.")
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
    t.n -= 1
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

mutable struct Iterator{K, V, T <: AbstractBST{K, V}} 
    tree::T
    from::AbstractNode{K, V}
    to::AbstractNode{K, V}
    function Iterator{K, V, T}(t::T,
                               from::AbstractNode{K, V},
                               to::AbstractNode{K, V}) where {K, V,
                                                              T <: AbstractBST{K, V}}
        @assert isnil(t, from)||isnil(t, to)||!(to.k < from.k)
        "`from` value cannot be more that the `to` value"
        return new{K, V, T}(t, from, to)
    end
end

Iterator(t::T,
         from::AbstractNode{K, V}=_minimum(t.root, t),
         to:: AbstractNode{K, V}=t.nil) where {K, V,
                                               T <: AbstractBST{K, V}} =
    Iterator{K, V, T}(t, from, to)

function Iterator(t::AbstractBST{K, V}, from::K, to::K) where {K, V}
    to < from && error("Cannot initialize iterator where `from > to`.")
    n, d = _search(t, t.root, from)
    if d == 0
        nn = _predecessor(n, t)
        while !(nn.k < n.k || n.k < nn.k) && nn !== n
            n = nn
            nn = _predecessor(n, t)
        end
    elseif d > 0
        n = _successor(n, t)
        isnil(t, n) && return Iterator(t, t.nil, t.nil)
    end
    fromN = n
    to < fromN && return Iterator(t, t.nil, t.nil)
    n, d = _search(t, t.root, to)
    nn = n
    if d == 0
        nn = _successor(n, t)
        while !(nn.k < n.k || n.k < nn.k) && !isnil(t, nn)
            n = nn
            nn = _successor(n, t)
        end
        n = nn
    elseif d < 0
        n = _predecessor(n, t)
    else
        n = _successor(n, t)
    end
    toN = n
    return Iterator(t, fromN, toN)
end

Base.IteratorSize(it::Iterator) = Base.SizeUnknown()

Base.iterate(it::Iterator) = iterate(it, it.from)

Base.eltype(it::Iterator{K, V, T}) where {K, V,
                                          T <: AbstractBST{K, V}} = Pair{K, V}

Base.similar(it::Iterator) = Vector{eltype(it)}()

function Base.iterate(it::Iterator{K, V, T},
                      n::AbstractNode{K, V}) where {K, V,
                                                    T <: AbstractBST{K, V}}
    n === it.to && return nothing
    return ((n.k => n.v), _successor(n, it.tree))
end

#
# Based on -
# Random binary search tree with equal elements
#   by Tomi A. Pasanen
#
# Published in Theoretical Computer Science 411 (2010) 3867–3872

mutable struct RandomizedBSTNode{K, V} <: AbstractNode{K, V}
    k::K
    v::V
    l::RandomizedBSTNode{K, V}
    r::RandomizedBSTNode{K, V}
    p::RandomizedBSTNode{K, V}
    n::Int

    function RandomizedBSTNode{K, V}() where {K, V}
        self = new{K, V}()
        self.n = 0
        self.l = self.r = self.p = self
    end
end


mutable struct RandomizedBinarySearchTree{K, V}  <: AbstractBST{K, V}
    root::RandomizedBSTNode{K, V}
    nil::RandomizedBSTNode{K, V}
    unique::Bool

    function RandomizedBinarySearchTree{K, V}() where {K, V}
        self = new{K, V}()
        nil = RandomizedBSTNode{K, V}()
        @assert nil.l === nil && nil.r === nil && nil.n == 0
        self.unique = false
        self.root = self.nil = nil
        return self
    end
end

function RandomizedBSTNode(t::RandomizedBinarySearchTree{K, V}, k::K, v::V) where {K, V}
    self = RandomizedBSTNode{K, V}()
    self.k, self.v, self.l, self.r, self.p, self.n = k, v, t.nil, t.nil, t.nil, 0
    return self
end

function _inorder2(f::Function, n::AbstractNode, t::AbstractBST)
    if !isnil(t, n)
        proceed = true
        proceed = (proceed && _inorder2(f, n.l, t))
        res = f(n, t)
        if res isa Bool
            proceed = (proceed && res)
        end
        proceed = (proceed && _inorder2(f, n.r, t))
        return proceed
    else
        return true
    end
end

function print_tree(n::RandomizedBinarySearchTree{K, V}) where {K, V}
    if isempty(n)
        println("[]")
    else
        println("Root = ", n.root.k, " and size = ", n.root.n)
        _inorder2(print_node, n.root, n)
    end
end

function print_node(n::RandomizedBSTNode{K, V}, t::RandomizedBinarySearchTree{K, V}) where {K, V}
  str = "[$(n.k)], left = $(n.l == t.nil ? "NULL" : n.l.k), right = $(n.r == t.nil ? "NULL" : n.r.k), parent = $(n.p == t.nil ? "NIL" : n.p.k) and size=$(n.n)"
  println(str)
  return str
end

isnil(t::RandomizedBinarySearchTree, n::RandomizedBSTNode) = n === t.nil
Base.empty!(t::RandomizedBinarySearchTree) = (t.root = t.nil)
Base.length(t::RandomizedBinarySearchTree) = t.root.n

function Base.insert!(t::RandomizedBinarySearchTree, k::K, v::V) where {K, V}
    r = _insert!(t.root, k, v, t, t.unique)
end

@inline function _insert!(node::RandomizedBSTNode{K, V},
                          k::K, v::V,
                          t::RandomizedBinarySearchTree, unique::Bool=true) where {K, V}
    rn = rand(0:node.n)
    if rn == node.n
        r = _insert_at_root!(node, k, v, unique, t)
        _fix_node!(t, r)
        return r
    else
        if k < node.k
            node.l = _insert!(node.l, k, v, t, unique)
            _fix_node!(t, node.l)
            _fix_node!(t, node)
        elseif !unique || (node.k < k)
            node.r =  _insert!(node.r, k, v, t, unique)
            _fix_node!(t, node.r)
            _fix_node!(t, node)
        else
            unique && error("Key $k already exists.")
        end
    end
    return node
end

@inline function _fix_node!(t::RandomizedBinarySearchTree{K, V}, n::RandomizedBSTNode{K, V}) where {K, V}
    if n != t.nil
        n.n = n.l.n + n.r.n + 1
        n.l != t.nil ? n.l.p = n : nothing
        n.r != t.nil ? n.r.p = n : nothing
    end
end

@inline function _insert_at_root!(t::RandomizedBSTNode{K, V},
                                 k::K, v::V, unique::Bool,
                                 tree::RandomizedBinarySearchTree{K, V}) where {K, V}
    node = RandomizedBSTNode(tree, k, v)
    node.p = t.p
    l, r = _split(t, k, v, unique, tree)
    node.l, node.r = l, r
    _fix_node!(tree, node)
    if isempty(tree) || tree.root == t
        tree.root = node
    end
    return node
end

# Given a k and a subtree - node returns (l, r) where all elements in l are < than k and all elements in r are > k
@inline function _split(node::RandomizedBSTNode{K, V}, k::K, v::V, unique::Bool,
                        t::RandomizedBinarySearchTree) where {K, V}
    if node == t.nil
       return t.nil, t.nil
    end

    if k < node.k
        r = node
        l, r.l = _split(node.l, k, v, unique, t)
        _fix_node!(t, r.l)
        _fix_node!(t, r)
        _fix_node!(t, l)
        return l, r
    elseif !unique || node.k < k
        l = node
        l.r, r = _split(node.r, k, v, unique, t)
        _fix_node!(t, l.r)
        _fix_node!(t, l)
        _fix_node!(t, r)
        return l, r
    else
        unique && error("Key $k already exists.")
    end
end

@inline function Base.delete!(t::RandomizedBinarySearchTree{K, V}, k::K) where {K, V}
    isempty(t) && error("Cannot delete from empty tree")
    x, s = _delete!(t.root, k, t)
    return s != t.nil ? s.k => s.v : nothing
end

@inline function _delete!(node::RandomizedBSTNode{K, V}, k::K, t::RandomizedBinarySearchTree{K, V}) where {K, V}
    found = t.nil
    if node == t.nil
        return t.nil, t.nil
    end
    if k < node.k
        node.l, found = _delete!(node.l, k, t)
    elseif k > node.k
        node.r, found = _delete!(node.r, k, t)
    else
        found = node
        node = _join(node.l,node.r, t)
        if (found == t.root)
            t.root = node
            node.p = t.nil
        end
    end
    _fix_node!(t, node)
    return node, found
end

@inline function _join(l::RandomizedBSTNode{K, V}, r::RandomizedBSTNode{K, V}, t::RandomizedBinarySearchTree{K, V}) where {K, V}
    m, n, total = l.n, r.n, l.n + r.n

    if total == 0
        return t.nil
    end

    rn = rand(0:total-1)
    if (rn < m)
        l.r = _join(l.r, r, t)
        _fix_node!(t, l.r)
        _fix_node!(t, l)
        return l
    else
         r.l = _join(l, r.l, t)
         _fix_node!(t, r.l)
         _fix_node!(t, r)
         return r
    end
end