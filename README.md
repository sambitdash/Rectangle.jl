# Rectangle

[![Build Status](https://travis-ci.org/sambitdash/Rectangle.jl.svg?branch=master)](https://travis-ci.org/sambitdash/Rectangle.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/vt9i3v1mndie7nkw?svg=true)](https://ci.appveyor.com/project/sambitdash/rectangle-jl)
[![codecov.io](http://codecov.io/github/sambitdash/Rectangle.jl/coverage.svg?branch=master)](http://codecov.io/github/sambitdash/Rectangle.jl?branch=master)

This is a simplified rectangle library for simple tasks with 2-D rectangles.
While the library will be enhanced for further functionalities, this will not be made to
work for higher dimensions. The numeric data types for most operations are preserved to the
extent practicable. However, where there is a natural affinity for the results to be `Float`
those are given emphasis. Currently the following methods are available.

## Methods for 2-D Rectangles

* `w(r)` - Width
* `h(r)` - Height
* `area(r)` - Area
* `perimeter(r)` - Perimeter
* `union(r1, r2)` - Union of two rectangles resulting in a larger rectangle.
* `intersect(r1, r2)` - Intersection of two rectangles.
* `inside(p, r)` - Point `p` is inside rectangle `r`
* `inside(ri, ro)` - Rectangle `ri` is fully enclosed in `ro`
* `to_plot_shape(r)` - `Shape` object to be used in `Plots` library.
* `projectX(r1, r2)` - Find overlap regions when projected onto X-axis.
* `projectY(r1, r2)` - Find overlap regions when projected onto Y-axis
* `visibleX(r1, r2)`, `visibleY(r1, r2)` - Projects the rectangles along the X-axis
(Y-axis) and returns a rectangle area which is completely visible from both rectangles.
* `has_x_overlap(r1, r2)`, `has_y_overlap(r1, r2)` - If rectangles have overlap along the
x-direction (y-direction).
* `avg_min_dist(r1, r2)` - Rectangles are essentially point sets. Hence, one can
perceive existence of a minimum distance of one point in `r1` from `r2`. Similar, distance
would also exist for every point in `r2` from `r1`.
* `min_dist(r1, r2)` - The gap between two rectangular regions. If there is overlap along a
specific direction 0 will be returned.
* `create_ordered_map(rects, values; dir=1)` - Ordered list of
  rectangles and associate data values. `dir=1` orders the rectangles
  by `x-axis` first and `2` by `y-axis`.
* `intersect(ordered_rect_map, rect)` - Return all the values for rectangles that intersect
with `rect`.
* `insert_rect!(ordered_rect_map, rect, value)` - Insert value associated with the `rect`.
* `delete_rect!(ordered_rect_map, rect)` - Delete associated value for the `rect`. Returns
the associated value.

## Methods for 2-D Lines

* `Line` - Representation of a line in 2-D.
* `isHorizontal(l)`, `isVertical(l)` - Returns if the line are horizontal or vertical
* `length(l)` - Length of the line
* `parallelogram_area(l, p)` - The area formed by the parallelogram formed by the line and
a point.
* `ratio(l,p)` - if point `p` lies on line `l`, then it will divide the line at a ratio 
`r : (1-r)` otherwise `nothing`
* `intersects(l1, l2)` - if line `l1` intersects `l2`. 

## Contribution

Pull Requests and Issues are ways to submit changes and enhancements.
