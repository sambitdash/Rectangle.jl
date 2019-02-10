using Test
using Rectangle

include("bstutils.jl")

@testset "Binary Search Trees" begin
    t = BinarySearchTree{Int, Int}()
    for i in 1:100
        insert!(t, i, 10i)
    end
    @test depth(t) == 100
    
    a = [4, 5, 3, 1, 10, 2, 7, 6, 8, 9]
    t = BinarySearchTree{Int, Int}()

    @test get!(t, 1, 2) == get(t, 1, 3)
    @test endswith(string(t), "Tree with 1 nodes.\nRoot at: 1.\n")
    @test get!(t, 2, 3) == get(t, 2, 4)
    @test get!(t, 2, 4) == 3
    @test get(t, 2, 4) == 3
    @test delete!(t, 1) == (1 => 2)
    @test delete!(t, 2) == (2 => 3)
    @test isempty(t)

    for i in a
        insert!(t, i, i*10)
    end
    @test collect(Iterator(t)) == [1=>10, 2=>20, 3=>30, 4=>40, 5=>50,
                                   6=>60, 7=>70, 8=>80, 9=>90, 10=>100]

    b = [i for i in 1:100]
    for i = 1:50
        n1 = rand(b)
        n2 = rand(b)
        b[n1], b[n2] = b[n2], b[n1]
    end
    s = BinarySearchTree{Int, Int}()
    for i in b
       insert!(s, i, 10i)
    end
    bb = [i for i in 1:10]
    @test collect(Iterator(s, -3, 10)) == Pair.(bb, 10bb)
    bb = [i for i in 11:20]
    @test collect(Iterator(s, bb[1], bb[end])) == Pair.(bb, 10bb)
    bb = [i for i in 101:103]
    @test collect(Iterator(s, bb[1], bb[end])) == []
    bb = [i for i in 99:103]
    @test collect(Iterator(s, bb[1], bb[end])) == [99 => 990, 100 => 1000]
    bb = [i for i in -3:2]
    @test collect(Iterator(s, bb[1], bb[end])) == [1 => 10, 2 => 20]
    bb = [i for i in -3:0]
    @test collect(Iterator(s, bb[1], bb[end])) == []
    for i = 1:10
        insert!(s, i, 10i)
    end
    @test collect(Iterator(s, 1, 2)) == [1 => 10, 1=>10, 2=>20, 2 => 20]
    @test length(t) == 10
    @test !isempty(t)
    @test maximum(t) == (10 =>100)
    @test minimum(t) == (1 => 10)
    data = tree_get_data(t)
    @test data[1] == sort(a)
    @test delete!(t, 5) == (5 => 50)
    @test delete!(t, 25) === nothing
    data = tree_get_data(t)
    @test data[2] == [10, 20, 30, 40, 60, 70, 80, 90, 100]
    empty!(t)
    @test isempty(t)
    @testset "Non-unique" begin
        t.unique = false
        n = 1000
        a = []
        for i = 1:n
            j = rand(1:10000)
            push!(a, j, i)
        end
        for i = 1:n
            insert!(t, a[i], i)
        end
        @test parentvalidity(t)
        @test bstvalidity(t)
        for i = 1:div(n, 2)
            delete!(t, a[i])
        end
        @test parentvalidity(t)
        @test bstvalidity(t)
        for i = 1:div(n, 2)
            insert!(t, a[i], i)
        end
        @test parentvalidity(t)
        @test bstvalidity(t)
    end
    @testset "Unique" begin
        t = BinarySearchTree{Int, Int}()
        t.unique = true
        n = 1000
        b = [i for i in 1:n]
        for i = 1:div(n, 2)
            x = rand(1:n)
            y = rand(1:n)
            b[x], b[y] = b[y], b[x]
        end
        a = Tuple{Int, Int}[]
        for i = 1:n
            insert!(t, b[i], i)
            push!(a, (b[i], i))
        end
        ka, kv = tree_get_data(t)
        aa = sort(a, lt= (x, y) -> x[1] < y[1])
        @test aa == collect(zip(ka, kv))
        @test bstvalidity(t)
        @test parentvalidity(t)
        @test_throws ErrorException insert!(t, 10, 10)

        # Randomly delete 50% of the data. Data in a are not sorted

        n_2 = div(n, 2)
        for i = 1:n_2
            Base.delete!(t, b[i])
        end
        bb = b[n_2+1:end]
        a = a[n_2+1:end]
        ka, kv = tree_get_data(t)
        aa = sort(a, lt= (x, y) -> x[1] < y[1])
        @test aa == collect(zip(ka, kv))
        @test bstvalidity(t)
        @test parentvalidity(t)
    end
end

@testset "Red and Black Trees" begin

    a = [4, 5, 3, 1, 10, 2, 7, 6, 8, 9]
    t = RBTree{Int, Int}()

    @test isempty(t)

    for i in a
        insert!(t, i, i*10)
    end
    @test collect(Iterator(t)) == [1=>10, 2=>20, 3=>30, 4=>40, 5=>50,
                                   6=>60, 7=>70, 8=>80, 9=>90, 10=>100]
    @test collect(Iterator(t, 3, 8)) == [3=>30, 4=>40, 5=>50,
                                         6=>60, 7=>70, 8=>80]
    @test parentvalidity(t)
    @test bstvalidity(t)
    @test rbvalidity(t)
    @test length(t) == 10
    @test !isempty(t)
    @test maximum(t) == (10 =>100)
    @test minimum(t) == (1 => 10)
    data = tree_get_data(t)
    @test data[1] == sort(a)
    @test delete!(t, 5) == (5 => 50)
    @test parentvalidity(t)
    @test bstvalidity(t)
    @test rbvalidity(t)
    data = tree_get_data(t)
    @test data[2] == [10, 20, 30, 40, 60, 70, 80, 90, 100]
    empty!(t)
    @test isempty(t)

    @testset "Non-unique" begin
        t.unique = false
        n = 10000
        a = Int[]
        for i = 1:n
            j = rand(1:1000)
            push!(a, j)
        end
        for i = 1:n
            insert!(t, a[i], i)
        end
        @test depth(t) <= 2*log2(n)
        @test parentvalidity(t)
        @test bstvalidity(t)
        @test rbvalidity(t)
        delete!(t, t.root.k)
        for i = 1:div(n, 2)
            delete!(t, a[i])
        end
        @test rbvalidity(t)
        @test parentvalidity(t)
        @test bstvalidity(t)

        for i = 1:div(n, 2)
            insert!(t, a[i], i)
        end
        @test rbvalidity(t)
        @test parentvalidity(t)
        @test bstvalidity(t)
        @test depth(t) <= 2*log2(n)
    end
    empty!(t)
    @testset "Unique" begin
        t.unique = true
        n = 10000
        b = [i for i in 1:n]
        
        for i = div(n, 2):-1:1
            x = rand(1:n)
            y = rand(1:n)
            b[x], b[y] = b[y], b[x]
        end
        a = Tuple{Int, Int}[]
        pa = Pair{Int, Int}[]
        for i = 1:n
            insert!(t, b[i], i)
            push!(a, (b[i], i))
            push!(pa, (b[i] => i))
        end
        @test depth(t) <= 2*log2(n)
        ka, kv = tree_get_data(t)
        aa = sort(a, lt= (x, y) -> x[1] < y[1])
        pa = sort(pa, lt= (x, y) -> x[1] < y[1])
        @test aa == collect(zip(ka, kv))
        @test pa == collect(Iterator(t))
        @test rbvalidity(t)
        @test bstvalidity(t)
        @test parentvalidity(t)
        #@test_throws ErrorException insert!(t, 10, 10)

        # Randomly delete 50% of the data. Data in a are not sorted
        n_2 = div(n, 2)
        for i = 1:n_2
            Base.delete!(t, b[i])
            ka, kv = tree_get_data(t)
        end
        bb = b[n_2+1:end]
        a  = a[n_2+1:end]
        ka, kv = tree_get_data(t)
        aa = sort(a, lt= (x, y) -> x[1] < y[1])
        @test aa == collect(zip(ka, kv))
        @test rbvalidity(t)
        @test bstvalidity(t)
        @test parentvalidity(t)
    end
end
