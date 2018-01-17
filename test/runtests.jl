using Rectangle
using Base.Test

@testset "Rectangle" begin
    @test Rect(0, 0, 10, 10) == Rect(0, 0, 10, 10)
    @test union(Rect(0, 0, 10, 5), Rect(11, -1, 12, 13)) == Rect(0, -1, 12, 13)
    @test intersect(Rect(0, 0, 10, 5), Rect(11, -1, 12, 13)) == nothing
    @test inside((1,2), Rect(0, 0, 10, 10))
    @test inside(Rect(1, 1, 3, 3), Rect(0, 0, 10, 10))
    @test Rect(0.0, 0.0, 10.0, 10.0) == Rect(0.0000001, 0.0000001, 10.0, 10.0)
    @test Rect(0.0, 0.0, 10.0, 10.0) != Rect(0.000002, 0.0000001, 10.0, 10.0)
end
