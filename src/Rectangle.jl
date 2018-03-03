__precompile__()

module Rectangle

export  Line,
            isHorizontal, isVertical, length, parallelogram_area,
            ratio, intersects,
        Rect,
            x, y, lx, ly, rx, ry, w, h, area, perimeter,
            union, intersect, inside,
            to_plot_shape,
            projectX, projectY,
            visibleX, visibleY,
            has_x_overlap, has_y_overlap,
            avg_min_dist, min_dist,
        OrderedRectMapX, OrderedRectMapY,
            create_ordered_map, get_intersect_data, insert_rect!, delete_rect!

include("utils.jl")
include("Line.jl")
include("Rect.jl")

end # module
