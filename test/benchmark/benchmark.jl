using BenchmarkTools

using Rectangle
using Rectangle: _search

include("../bstutils.jl")

begin
    t = BinarySearchTree{Int, Int}()
    t.unique = false
    n = 1000
    a = []
    for i = 1:n
        j = rand(1:10000000000)
        push!(a, j, i)
    end
    for i = 1:n
        insert!(t, a[i], i)
    end
    print("Base.findfirst call to find a number in array: \t\t")
    @btime begin
        findfirst(x -> x == 15, a)
    end

    print("_search a number in a BinarySearchTree : \t\t")
    @btime begin
        n, d = _search(t, t.root, 15)
    end

    @assert parentvalidity(t)
    @assert bstvalidity(t)
    print("delete 50% from BinarySearchTree and add again: \t")
    @btime begin
        for i = 1:div(n, 2)
            delete!(t, a[i])
        end
        for i = 1:div(n, 2)
            insert!(t, a[i], i)
        end
    end
end

begin
    t = RBTree{Int, Int}()
    t.unique = false
    n = 10000
    a = []
    for i = 1:n
        j = rand(1:10000000000)
        push!(a, j, i)
    end
    for i = 1:n
        insert!(t, a[i], i)
    end
    print("Base.find call to find a number in array: \t\t")
    @btime findfirst(x -> x == 15, a)
    print("_search a number in a RBTree : \t\t\t\t")
    @btime begin
        n, d = _search(t, t.root, 15)
    end
    @assert parentvalidity(t)
    @assert bstvalidity(t)
    print("delete 50% from RBTree and add again: \t\t\t")
    @btime begin
        for i = 1:div(n, 2)
            delete!(t, a[i])
        end
        for i = 1:div(n, 2)
            insert!(t, a[i], i)
        end
    end
end
