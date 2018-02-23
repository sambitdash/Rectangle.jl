using Rectangle
using Base.Test

@testset "Rectangle" begin
    @test Rect(0.0, 0.0, 10, 10) == Rect(0, 0, 10, 10)
    @test union(Rect(0, 0, 10, 5), Rect(11, -1, 12, 13)) == Rect(0, -1, 12, 13)
    @test intersect(Rect(0.0, 0, 10, 5), Rect(11, -1, 12, 13)) == nothing
    @test intersect(Rect(0.0, 0.0, 5.0, 2.0), Rect(4.0, 2.0, 10.0, 10.0)) == nothing
    @test inside((1,2), Rect(0, 0, 10, 10))
    @test inside(Rect(1, 1, 3, 3), Rect(0, 0, 10, 10))
    @test Rect(0, 0, 10, 10) == Rect(0.0000001, 0.0000001, 10.0, 10.0)
    @test Rect(0.0, 0.0, 10.0, 10.0) != Rect(0.000002, 0.0000001, 10.0, 10.0)
    @test perimeter(Rect(0, 0, 1, 10)) == 22
    @test area(Rect(0, 0, 1, 10))      == 10
    @test perimeter(Rect(0, 0, 1//2, 1)) == 3

    @test  has_x_overlap(Rect(0.0, 0.0, 10.0, 1.0), Rect(3.0, 2.0, 11.0, 4.0))
    @test !has_y_overlap(Rect(0.0, 0.0, 10.0, 1.0), Rect(3.0, 2.0, 11.0, 4.0))

    @test  has_y_overlap(Rect(0.0, 0.0, 1.0, 10.0), Rect(2.0, 3.0, 4.0, 11.0))
    @test !has_x_overlap(Rect(0.0, 0.0, 1.0, 10.0), Rect(2.0, 3.0, 4.0, 11.0))

    @test visibleX(Rect(0.0, 0.0, 10.0, 1.0), Rect(3.0, 2.0, 11.0, 4.0)) ==
        Rect(3.0, 1.0, 10.0, 2.0)
    @test visibleY(Rect(0.0, 0.0, 10.0, 1.0), Rect(3.0, 2.0, 11.0, 4.0)) ==
            nothing

    @test visibleY(Rect(0.0, 0.0, 1.0, 10.0), Rect(2.0, 3.0, 4.0, 11.0)) ==
        Rect(1.0, 3.0, 2.0, 10.0)
    @test visibleX(Rect(0.0, 0.0, 1.0, 10.0), Rect(2.0, 3.0, 4.0, 11.0)) ==
        nothing

    @test begin
        r = (8.928571428571429, 4.583333333333334)
        v = avg_min_dist(Rect(0,0,10,10), Rect(15,5,20,20))
        abs(v[1] - r[1]) < 1e-6 && abs(v[2] - r[2]) < 1e-6
    end

    @test begin
        r = (4.583333333333334, 8.928571428571429)
        v = avg_min_dist(Rect(0,0,10,10), Rect(5,15,20,20))
        abs(v[1] - r[1]) < 1e-6 && abs(v[2] - r[2]) < 1e-6
    end

    @test begin
        r = (0.8333333333333334, 8.928571428571429)
        v = avg_min_dist(Rect(0,0,10,10), Rect(0,15,15,20))
        abs(v[1] - r[1]) < 1e-6 && abs(v[2] - r[2]) < 1e-6
    end

    @test min_dist(Rect(0,0,10,10), Rect(0,15,15,20)) == (0, 5)
    @test min_dist(Rect(0,0,10,10), Rect(11,15,15,20)) == (1, 5)

    @test to_plot_shape(Rect(1, 2, 3, 4)) == ([1, 3, 3, 1], [2, 2, 4, 4])

end
