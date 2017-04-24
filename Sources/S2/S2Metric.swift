//
//  S2Metric.swift
//  S2Geometry
//
//  Created by Marc Rollin on 5/8/17.
//  Copyright © 2017 Marc Rollin. All rights reserved.
//

import Foundation

/// A Metric is a measure for cells. It is used to describe the shape and size
/// of cells. They are useful for deciding which cell level to use in order to
/// satisfy a given condition (e.g. that cell vertices must be no further than
/// "x" apart). You can use the Value(level) method to compute the corresponding
/// length or area on the unit sphere for cells at a given level. The minimum
/// and maximum bounds are valid for cells at all levels, but they may be
/// somewhat conservative for very large cells (e.g. face cells).
struct S2Metric {

    /// Either 1 or 2, for a 1D or 2D metric respectively.
    let dimension: Int

    /// Scaling factor for the metric.
    /// Must be multiplied by a length or area in (s,t)-space to get a useful value.
    let derivative: Double

    /// Defined metrics.
    ///
    /// Each cell is bounded by four planes passing through its four edges and
    /// the center of the sphere. These metrics relate to the angle between each
    /// pair of opposite bounding planes, or equivalently, between the planes
    /// corresponding to two different s-values or two different t-values.
    static let minAngleSpan = S2Metric(dimension: 1, derivative: 4.0 / 3)
    static let avgAngleSpan = S2Metric(dimension: 1, derivative: .pi / 2)
    static let maxAngleSpan = S2Metric(dimension: 1, derivative: 1.704897179199218452)

    /// The width of geometric figure is defined as the distance between two
    /// parallel bounding lines in a given direction. For cells, the minimum
    /// width is always attained between two opposite edges, and the maximum
    /// width is attained between two opposite vertices. However, for our
    /// purposes we redefine the width of a cell as the perpendicular distance
    /// between a pair of opposite edges. A cell therefore has two widths, one
    /// in each direction. The minimum width according to this definition agrees
    /// with the classic geometric one, but the maximum width is different. (The
    /// maximum geometric width corresponds to MaxDiag defined below.)
    ///
    /// The average width in both directions for all cells at level k is approximately
    ///     avgAngleSpan.value(at: k)
    ///
    /// The width is useful for bounding the minimum or maximum distance from a
    /// point on one edge of a cell to the closest point on the opposite edge.
    /// For example, this is useful when growing regions by a fixed distance.
    static let minWidth = S2Metric(dimension: 1, derivative: 2 * 2.squareRoot() / 3)
    static let avgWidth = S2Metric(dimension: 1, derivative: 1.434523672886099389)
    static let maxWidth = S2Metric(dimension: 1, derivative: maxAngleSpan.derivative)

    /// The edge length metrics can be used to bound the minimum, maximum,
    /// or average distance from the center of one cell to the center of one of
    /// its edge neighbors. In particular, it can be used to bound the distance
    /// between adjacent cell centers along the space-filling Hilbert curve for
    /// cells at any given level.
    static let minEdge = S2Metric(dimension: 1, derivative: 2 * 2.squareRoot() / 3)
    static let avgEdge = S2Metric(dimension: 1, derivative: 1.459213746386106062)
    static let maxEdge = S2Metric(dimension: 1, derivative: maxAngleSpan.derivative)

    /// maxEdgeAspect is the maximum edge aspect ratio over all cells at any level,
    /// where the edge aspect ratio of a cell is defined as the ratio of its longest
    /// edge length to its shortest edge length.
    private static let maxEdgeAspect = 1.442615274452682920

    static let minArea = S2Metric(dimension: 2, derivative: 8 * 2.squareRoot() / 9)
    static let avgArea = S2Metric(dimension: 2, derivative: 4 * .pi / 6)
    static let maxArea = S2Metric(dimension: 2, derivative: 2.635799256963161491)

    /// The maximum diagonal is also the maximum diameter of any cell,
    /// and also the maximum geometric width (see the comment for widths). For
    /// example, the distance from an arbitrary point to the closest cell center
    /// at a given level is at most half the maximum diagonal length.
    static let minDiagonal = S2Metric(dimension: 1, derivative: 8 * 2.squareRoot() / 9)
    static let avgDiagonal = S2Metric(dimension: 1, derivative: 2.060422738998471683)
    static let maxDiagonal = S2Metric(dimension: 1, derivative: 2.438654594434021032)

    /// maxDiagonalAspect is the maximum diagonal aspect ratio over all cells at any
    /// level, where the diagonal aspect ratio of a cell is defined as the ratio
    /// of its longest diagonal length to its shortest diagonal length.
    static let maxDiagonalAspect = sqrt(3)
}

extension S2Metric {

    /// - returns: the value of the metric at the given level.
    func value(at level: Int) -> Double {
        return ldexp(derivative, -dimension * level)
    }
}
