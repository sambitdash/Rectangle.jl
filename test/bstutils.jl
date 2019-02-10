import Rectangle: _inorder, isnil

function tree_get_data(t::AbstractBST{K, V}) where {K, V}
    karr = Vector{K}()
    varr = Vector{V}()
    
    for p in collect(Iterator(t))
        push!(karr, p[1])
        push!(varr, p[2])
    end
    return karr, varr
end

function bstvalidity(t::AbstractBST)
    valid = true
    _inorder(t.root, t) do n
        !valid && return valid
        r1 = (!isnil(t, n.l) && !(n < n.l)) || isnil(t, n.l)
        r2 = (!isnil(t, n.r) && !(n.r < n)) || isnil(t, n.r)
        valid &= (r1 & r2)
        return valid
    end
    return valid
end

function parentvalidity(t::AbstractBST)
    valid = true
    _inorder(t.root, t) do n
        @assert !isnil(t, n)
        !valid && return valid
        r1 = ( isnil(t, n.p) && (t.root === n))
        r2 = (!isnil(t, n.p) && (n.p.l === n || n.p.r === n))
        @assert isnil(t, n.p) || (n.p.l !== n.p.r)
        valid &= (r1 | r2)
        return valid
    end
    return valid    
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
function rbvalidity(t::RBTree{K, V}) where {K, V}
    valid = (t.root.red == false)
    !valid && error("Invalid value at root: $(t.root.k)")
    valid = (valid && (t.nil.red == false))
    !valid && error("Invalid value at nil")
    _inorder(t.root, t) do n
        valid = (valid && ((n.red && !n.l.red && !n.r.red && !n.p.red) || !n.red))
        !valid && println("Invalid value at $(n.k)")
        cl = cr = 0
        tn = n
        while !isnil(t, tn)
            cl += (!tn.red ? 1 : 0)
            tn = tn.l
        end
        tn = n
        while !isnil(t, tn)
            cr += (!tn.red ? 1 : 0)
            tn = tn.r
        end
        valid = (valid && cl == cr)
        !valid && println("Invalid balance value at $(n.k): $(cl) and $(cr)")
        return valid
    end
    return valid
end
