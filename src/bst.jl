# This code is very similar to BST implementation of Algorithms book of
# Cormen, Leiserson, Rivest, Stein (3rd edition)

export BinarySearchTree,
    tree_insert!,
    tree_delete!,
    tree_search,
    tree_inorder_walk,
    tree_get_data

mutable struct Node{K, V}
    k::K
    v::V
    parent::Union{Void, Node{K, V}}
    right::Union{Void, Node{K, V}}
    left::Union{Void, Node{K, V}}
    Node{K, V}(k::K, v::V) where {K, V} = new(k, v, nothing, nothing, nothing)
end

Node(k::K, v::V) where {K, V} = Node{K, V}(k, v)

@inline function show(io::IO, x::Node)
    print(io, "key:", x.k, ' ', "val:", x.v, '\n')
    if left(x) !== nothing
        println(io, "left:", notvoid(left(x)).k)
    else
        println(io, "left:", nothing)        
    end
    if right(x) !== nothing
        println(io, "right:", notvoid(right(x)).k)
    else
        println(io, "right:", nothing)        
    end
    return io
end

mutable struct BinarySearchTree{K, V}
    root::Union{Void, Node{K, V}}
    n::Int
    BinarySearchTree{K, V}() where{K, V} = new(nothing, 0)
end

@inline Base.length(t::BinarySearchTree) = t.n
@inline Base.isempty(t::BinarySearchTree) = t.n == 0
@inline Base.empty!(t::BinarySearchTree) = ((t.root, t.n) = (nothing, 0))
@inline tree_search(t::BinarySearchTree{K, V}, k::K) where {K, V}  = tree_search(t.root, k)
@inline tree_inorder_walk(f::Function, t::BinarySearchTree) = inorder_tree_walk(f, t.root)
@inline tree_get_data(t::BinarySearchTree) = tree_get_data(t.root)

@inline function tree_get_data(n::Node{K, V}) where {K, V}
    karr = Vector{K}()
    varr = Vector{V}()

    inorder_tree_walk((k, v) -> begin
                      push!(karr, k)
                      push!(varr, v)
                      end, n)
    return karr, varr
end

key_update!(t::BinarySearchTree, y::Node) = nothing

function tree_insert!(t::BinarySearchTree{K, V}, k::K, v::V) where {K, V}
    z = Node(k, v)
    y = nothing
    x = root(t)
    while x !== nothing
        xx = notvoid(x)
        y = xx
        x = key(z) < key(xx) ? left(xx) : right(xx)
    end
    parent!(z, y)
    if y === nothing
        root!(t, z)
    else
        ty = notvoid(y)
        if key(z) < key(ty)
            left!(ty, z)
        else
            right!(ty, z)
        end
        key_update!(t, y)
    end
    t.n += 1
end

@inline function tree_delete!(t::BinarySearchTree{K, V}, k::K) where {K, V}
    karr = Vector{K}()
    varr = Vector{V}()
    x = tree_search(t, k)
    while x !== nothing
        dn = tree_delete!(t, notvoid(x))
        push!(karr, dn.k)
        push!(varr, dn.v)
        x = tree_search(t, k)
    end
    return (karr, varr)
end

function tree_delete!(t::BinarySearchTree, z::Node)
    y = left(z) === nothing || right(z) === nothing ? z : tree_successor(z)
    x = left(y) !== nothing ? left(y) : right(y)
    if x !== nothing
        parent!(notvoid(x), parent(y))
        key_update!(t, notvoid(x))
    end
    if parent(y) === nothing
        root!(t, x)
    else
        py = notvoid(parent(y))
        if y === left(py)
            left!(py, x)
        else
            right!(py, x)
        end
    end
    if y !== z
        exchange!(z, y)
    end
    t.n -= 1
    return y
end

@inline root(t) = t.root
@inline root!(t, x) = (t.root = x)

@inline left(x)   = x.left
@inline right(x)  = x.right
@inline parent(x) = x.parent

@inline left!(x, y)   = (x.left = y)
@inline right!(x, y)  = (x.right = y)
@inline parent!(x, y) = (x.parent = y)
@inline function exchange!(y, x)
    y.k, x.k = x.k, y.k
    y.v, x.v = x.v, y.v
    y
end

@inline key(x)    = x.k
@inline value(x)  = x.v

@inline function inorder_tree_walk(f::Function, x)
    x === nothing && return nothing
    x = notvoid(x)
    inorder_tree_walk(f, left(x))
    f(key(x), value(x))
    inorder_tree_walk(f, right(x))
    return nothing
end

#Julia ==(x, y) = x === y
# Always use < to define all logical operators

@inline function tree_search(x, k)
    x === nothing && return x
    x = notvoid(x)
    k < key(x) && return tree_search(left(x), k)
    k > key(x) && return tree_search(right(x), k)
    return x
end

tree_minimum(x) = tree_extrema(left, x)
tree_maximum(x) = tree_extrema(right, x)

@inline function tree_extrema(f::Function, x)
    while f(x) !== nothing
        x = notvoid(f(x))
    end
    return x
end

tree_successor(x)   = tree_pred_succ(right, tree_minimum, x)
tree_predecessor(x) = tree_pred_succ(left,  tree_maximum, x)

@inline function tree_pred_succ(f::Function, g::Function, x)
    f(x) !== nothing && return g(notvoid(f(x)))
    y = parent(x)
    while y !== nothing && x === f(y)
        x = notvoid(y)
        y = parent(notvoid(y))
    end
    return y
end

