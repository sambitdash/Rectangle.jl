using Test
using Rectangle
using Rectangle: isnil

const VISUALIZATION=false

function xy_predicate(v, sdir)
    dir  = sdir == 1 ? 2 : 1
    odir = dir == 1 ? 2 : 1

    sz = size(v)

    vloc = dir == 1 ? div(sz[dir], 4) : div(sz[dir], 2)

    vloc <= 8 && return nothing, nothing, (0, 0, (0, 0), 0)
    
    prange = parentindices(v)
    loc = vloc + prange[dir][1] - 1
    range = (prange[odir][1] + firstindex(v, odir) -1,
             prange[odir][1] + lastindex(v, odir)  -1)

    nvl, nvr = dir == 1 ? ((@view v[1:vloc, :]), (@view v[vloc+1:end, :])) :
        ((@view v[:, 1:vloc]), (@view v[:, vloc+1:end]))

    return (()->xy_predicate(nvl, dir),
            ()->xy_predicate(nvr, dir),
            (dir, loc, range, 0))
end

@testset "XY Tree Tests" begin
    m = falses(64, 64)
    
    t = XYTree{Int, Int}() do
        xy_predicate(m, 0)
    end

    ls, vs = get_values(t)

    @test ls == [Line(32, 1, 32, 16),
                 Line(1, 16, 64, 16),
                 Line(16, 17, 16, 28),
                 Line(1, 28, 32, 28), 
                 Line(1, 37, 16, 37), 
                 Line(16, 29, 16, 64),
                 Line(17, 37, 32, 37),
                 Line(32, 17, 32, 64),
                 Line(48, 17, 48, 28),
                 Line(33, 28, 64, 28),
                 Line(33, 37, 48, 37),
                 Line(48, 29, 48, 64),
                 Line(49, 37, 64, 37)]
    @test vs == zeros(Int, 13)
end

@static if VISUALIZATION

    import PyPlot
    using PyCall
    
    function draw_tree(n, t, ax)
        isnil(t, n) && return 
        color = "#ff0000"
        if n.dir == 1
            vx, vy = [n.range...], [n.loc, n.loc] 
        else
            vx, vy = [n.loc, n.loc], [n.range...]
        end
        pyl = PyPlot.plt[:Line2D](vx, vy, color=color)
        ax[:add_line](pyl)
        draw_tree(n.l, t, ax)
        draw_tree(n.r, t, ax)
    end

    function plot_map(bimg, t)
        fig = PyPlot.gcf()
        PyPlot.clf()
        fig[:clf](true)
        fig[:set_dpi](72f0)

        sz = size(bimg)
        hpi = sz[1]/16f0
        wpi = sz[2]/16f0
        println(hpi, " ", wpi)
        fig[:set_figwidth](wpi, forward=true)
        fig[:set_figheight](hpi, forward=true)

        ax = fig[:gca]()
    
        ax[:set_xlim](0f0, sz[2])
        ax[:set_ylim](0f0, sz[1])

        img = map(x->x ? 0xff : 0x00, bimg)
        
        imgplot = PyPlot.imshow(img)

        draw_tree(t.root, t, ax)
        PyPlot.show()
    end
end
