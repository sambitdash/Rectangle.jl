__precompile__()

module Rectangle

export  Line,
            isHorizontal, isVertical, length, parallelogram_area,
            ratio, intersects, merge_axis_aligned, sx, sy, ex, ey,
        Rect,
            x, y, lx, ly, rx, ry, w, h, area, perimeter, hlines, vlines, lines, olines,
            union, intersects, inside, cg,
            to_plot_shape,
            projectX, projectY,
            visibleX, visibleY,
            has_x_overlap, has_y_overlap,
            avg_min_dist, min_dist,
        OrderedRectMapX, OrderedRectMapY,
            create_ordered_map, get_intersect_data, insert_rect!, delete_rect!,
        pcTol


include("utils.jl")
include("Line.jl")
include("Rect.jl")
include("bst.jl")

end # module
