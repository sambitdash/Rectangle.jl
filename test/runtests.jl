using Rectangle
using Base.Test

@testset "Rectangle" begin
    @test Rect(0.0, 0.0, 10, 10) == Rect(0, 0, 10, 10)
    @test Rect([0 10; 0 10]) == Rect(0, 0, 10, 10)
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

    @test x(Rect(0, 5, 10, 10)) == [0, 10]
    @test y(Rect(0, 5, 10, 10)) == [5, 10]

    @test  has_x_overlap(Rect(0.0, 0.0, 10.0, 1.0), Rect(3.0, 2.0, 11.0, 4.0))
    @test !has_y_overlap(Rect(0.0, 0.0, 10.0, 1.0), Rect(3.0, 2.0, 11.0, 4.0))

    @test  has_y_overlap(Rect(0.0, 0.0, 1.0, 10.0), Rect(2.0, 3.0, 4.0, 11.0))
    @test !has_x_overlap(Rect(0.0, 0.0, 1.0, 10.0), Rect(2.0, 3.0, 4.0, 11.0))

    @test visibleX(Rect(0.0, 0.0, 10.0, 1.0), Rect(3.0, 2.0, 11.0, 4.0)) ==
        Rect(3.0, 1.0, 10.0, 2.0)
    @test visibleY(Rect(0.0, 0.0, 10.0, 1.0), Rect(3.0, 2.0, 11.0, 4.0)) ==
            nothing

    @test visibleY(Rect(0.0, 0.0, 1.0, 10.0), Rect(2, 3, 4, 11)) ==
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

    @test begin
        r = (0.0, 9.166666666666668)
        v = avg_min_dist(Rect(0,0,10,10), Rect(0,15,10,20))
        abs(v[1] - r[1]) < 1e-6 && abs(v[2] - r[2]) < 1e-6
    end

    @test begin
        v = projectX(Rect(0,0,10,10), Rect(0,15.0,10,20))
        @assert v[1] == (nothing, nothing)
        @assert v[2] == (Rect(0.0,0.0,10.0,10.0), Rect(0.0,15.0,10.0,20.0))
        v[3] == (nothing, nothing)
    end

    @test begin
        r = (7.0, 7.0)
        v = avg_min_dist(Rect(0,0,6,6), Rect(10,10,16,16))
        abs(v[1] - r[1]) < 1e-6 && abs(v[2] - r[2]) < 1e-6
    end
                                                               
    @test begin
        r = (0, 5)
        v = min_dist(Rect(0,0,10,10.0), Rect(0,15,15,20))
        abs(v[1] - r[1]) < 1e-6 && abs(v[2] - r[2]) < 1e-6
    end
    @test min_dist(Rect(0,0,10,10), Rect(11,15,15,20)) == (1, 5)

    @test to_plot_shape(Rect(1, 2, 3, 4)) == ([1, 3, 3, 1], [2, 2, 4, 4])

    rects = [Rect(0, 20*i, 100, 10 + 20*i) for i = 1:10]
    is = [i for i=1:10]
    ormy = create_ordered_map(rects, is, dir=2)
    v = insert_rect!(ormy, Rect(0, 20, 100, 30), 11)
    @test delete_rect!(ormy, Rect(0, 20, 100, 30)) == 11
    @test intersect(ormy, Rect(0, 0, 110, 55)) == [(Rect(0, 40, 100, 50), 2)]

    ormx = create_ordered_map(rects, is, dir=1)
    v = insert_rect!(ormx, Rect(0, 20, 100, 30), 11)
    @test delete_rect!(ormx, Rect(0, 20, 100, 30)) == 11
    @test intersect(ormx, Rect(0, 0, 110, 55)) == [(Rect(0, 40, 100, 50), 2)]

    @test hlines(Rect(0, 0, 10, 10)) == (Line(0, 0, 10, 0), Line(0, 10, 10, 10))
    @test vlines(Rect(0, 0, 10, 10)) == (Line(0, 0, 0, 10), Line(10, 0, 10, 10))
    @test lines(Rect(0, 0, 10, 10)) == [Line(0, 0, 10, 0), Line(0, 10, 10, 10),
                                        Line(0, 0, 0, 10), Line(10, 0, 10, 10)] 
    @test olines(Rect(0, 0, 10, 10)) == [Line(0, 0, 10, 0), Line(10, 0, 10, 10),
                                         Line(10, 10, 0, 10), Line(0, 10, 0, 0)]
    @test intersects(Rect(0, 0, 10, 10.0), Line(-1, -1, 11.0, 11))
    @test intersects(Rect(0, 0, 10, 10), Line(5, -5, 11, 11))
    @test !intersects(Rect(0, 0, 10, 10), Line(11, 0, 11, 11))
end

@testset "Line" begin
    @test Line([0 10; 0 10]) == Line(0.0, 0, 10, 10)
    @test isHorizontal(Line(0.0, 0, 10, 0))
    @test !isHorizontal(Line(0.0, 0, 10, 1)) 
    @test isVertical(Line(10, 0, 10, 10))
    @test !isVertical(Line(10, 0, 11.0, 10.0))
    @test parallelogram_area([0 0; 10 0; 0 20]') == 200
    @test length(Line(0, 0, 3, 4)) == 5.0
    @test ratio(Line(0, 0, 5, 10.0), [1, 2]) == 0.2
    @test ratio(Line(0, 0, 5, 10.0), [2, 3]) == nothing
    @test ratio(Line(0.0, 0, 0, 10), [0, 5]) == 0.5
    @test ratio(Line(0.0, 0, 0, 10), [1, 5]) == nothing
    @test intersects(Line(0, 0, 10, 10), Line(10, 0, 0.0, 10))
    @test intersects(Line(0, 0, 10, 10), Line(5, 5, 0.0, 10))
    @test !intersects(Line(0, 0, 4, 4), Line(5, 5, 0.0, 10))
    @test !intersects(Line(0, 0, 4, 4), Line(10, 0, 0.0, 10))
    @test reverse(Line(0, 0, 10, 20)) == Line(10, 20, 0, 0)
end
