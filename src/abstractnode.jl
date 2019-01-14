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
        t.n -= 1
        return n.k => n.v
    else
        return nothing
    end
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

mutable struct Iterator{K, V, T, N}
    tree::T
    from::N
    to::N
    function Iterator{K, V, T, N}(t::T,
                                  from::N,
                                  to::N) where {K, V,
                                                T <: AbstractBST{K, V},
                                                N <: AbstractNode{K, V}}
        @assert isnil(t, from) || isnil(t, to) || !(to.k < from.k)
        "`from` value cannot be more that the `to` value"
        new{K, V, T, N}(t, from, to)
    end
end

function Iterator(t::T, from::N=_minimum(t.root, t),
                  to::N=t.nil) where {K, V,
                                      T <: AbstractBST{K, V},
                                      N <: AbstractNode{K, V}}
    Iterator{K, V, T, N}(t, from, to)
end

function Iterator(t::T, from::K, to::K) where {K, V, T <: AbstractBST{K, V}}
    to < from && error("Cannot initialize iterator where `from > to`.")
    n, d = _search(t, t.root, from)
    if d == 0
        nn = _predecessor(n, t)
        while nn.k == n.k && nn !== n
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
        while nn.k == n.k && !isnil(t, nn)
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

function Base.iterate(it::Iterator{K, V, T, N},
                      n::N) where {K, V,
                                   T <: AbstractBST{K, V},
                                   N <: AbstractNode{K, V}}
    n === it.to && return nothing
    return ((n.k => n.v), _successor(n, it.tree))
end
