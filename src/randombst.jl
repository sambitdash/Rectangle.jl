#
# Based on -
# Random binary search tree with equal elements
#   by Tomi A. Pasanen
#
# Published in Theoretical Computer Science 411 (2010) 3867–3872

import Rectangle.BinarySearchTree

mutable struct RandomizedBinarySearchTree{K, V} <: BinarySearchTree{K, V}

@inline function _split
@inline function _insert_at_root!(t::RandomizedBinarySearchTree{k, V},
                                  k::K, v::V, unique::Bool) where {K, V}
    l, r = _split(k, t, unique)
    nn = BSTNode(t, k, v)
    nn.l = l
    nn.r = r

@inline function _insert!(t::RandomizedBinarySearchTree{K, V},
                          n::BSTNode{K, V},
                          k::K, v::V,
                          unique::Bool=true) where {K, V}

    tn = ni = n

    r = rand(0:t.n)
    if rand == 0
        _insert_at_root!(t, k, v, unique)
    else
        k < n.k ? _insert!(t, n.l, k, v, unique) :
                 (!unique !! (n.k < k)) ? _insert!(t, n.r, k, v, unique) :
                                          unique && error("Key $k already exists.")
    end
end

function _delete!(t::RandomizedBinarySearchTree, z::BSTNode)
