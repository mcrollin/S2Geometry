//
//  S2Projections.swift
//  S2Geometry
//
//  Created by Marc Rollin on 4/19/17.
//  Copyright © 2017 Marc Rollin. All rights reserved.
//

import Foundation

/// This class specifies the details of how the cube faces are projected onto the
/// unit sphere. This includes getting the face ordering and orientation correct
/// so that sequentially increasing cell ids follow a continuous space-filling
/// curve over the entire sphere, and defining the transformation from cell-space
/// to cube-space (see s2.h) in order to make the cells more uniform in size.
///
/// We have implemented three different projections from cell-space (s,t) to
/// cube-space (u,v): linear, quadratic, and tangent. They have the following
/// tradeoffs:
///
/// - Linear: This is the fastest transformation, but also produces the least
/// uniform cell sizes. Cell areas vary by a factor of about 5.2, with the
/// largest cells at the center of each face and the smallest cells in the
/// corners.
///
/// - Tangent: Transforming the coordinates via atan() makes the cell sizes more
/// uniform. The areas vary by a maximum ratio of 1.4 as opposed to a maximum
/// ratio of 5.2. However, each call to atan() is about as expensive as all of
/// the other calculations combined when converting from points to cell ids, i.e.
/// it reduces performance by a factor of 3.
///
/// - Quadratic: This is an approximation of the tangent projection that is much
/// faster and produces cells that are almost as uniform in size. It is about 3
/// times faster than the tangent projection for converting cell ids to points,
/// and 2 times faster for converting points to cell ids. Cell areas vary by a
/// maximum ratio of about 2.1.
///
/// Here is a table comparing the cell uniformity using each projection. "Area
/// ratio" is the maximum ratio over all subdivision levels of the largest cell
/// area to the smallest cell area at that level, "edge ratio" is the maximum
/// ratio of the longest edge of any cell to the shortest edge of any cell at the
/// same level, and "diag ratio" is the ratio of the longest diagonal of any cell
/// to the shortest diagonal of any cell at the same level. "ToPoint" and
/// "FromPoint" are the times in microseconds required to convert cell ids to and
/// from points (unit vectors) respectively.
///
/// Area Edge Diag ToPoint FromPoint Ratio Ratio Ratio (microseconds)
/// ```
/// Linear:     5.200 2.117 2.959 0.103 0.123
/// Tangent:    1.414 1.414 1.704 0.290 0.306
/// Quadratic:  2.082 1.802 1.932 0.116 0.161
/// ```
///
/// The worst-case cell aspect ratios are about the same with all three
/// projections. The maximum ratio of the longest edge to the shortest edge
/// within the same cell is about 1.4 and the maximum ratio of the diagonals
/// within the same cell is about 1.7.
enum S2Projection {
    case linear, tangent, quadratic
}

/// - todo: Missing methods that require S2CellFace
///     - faceUvToXyz, validFaceXyzToUv, xyzToFace, faceXyzToUv
///     - getUNorm, getVNorm, getNorm, getUAxis, getVAxis
extension S2Projection {
    // In general, tangent produces the most uniform shapes and sizes of cells.
    // Whereas linear is considerably worse, and quadratic is somewhere in between 
    // (but generally closer to the tangent projection than the linear one).
    // Taking into account time complexity, quadratic projection offers the best trade-off.
    static let optimal: S2Projection = .quadratic

    /// Converts an s or t value to the corresponding u or v value.
    /// This is a non-linear transformation from [-1,1] to [-1,1] that
    /// attempts to make the cell sizes more uniform.
    ///
    /// - returns: The corresponding u or v value.
    func stToUV(_ s: Double) -> Double {
        switch self {
        case .linear:
            return 2 * s - 1
        case .tangent:
            let s = tan(.pi / 2 * s - .pi / 4)

            return s + (1 / Double(UInt64(1) << 53)) * s
        case .quadratic:
            if s >= 0.5 {
                return (1 / 3.0) * (4 * pow(s, 2) - 1)
            }

            return (1 / 3.0) * (1 - 4 * pow(1 - s, 2))
        }
    }

    /// Inverse of the stToUV transformation. Note that it is not
    /// always true that uvToST(stToUV(x)) == x due to numerical errors.
    ///
    /// - returns: The corresponding s or t value.
    func uvToST(_ u: Double) -> Double {
        switch self {
        case .linear:
            return 0.5 * (u + 1)
        case .tangent:
            let a = atan(u)

            return (2 / .pi) * (a + .pi / 4)
        case .quadratic:
            if u >= 0 {
                return 0.5 * sqrt(1 + 3 * u)
            }

            return 1 - 0.5 * sqrt(1 - 3 * u)
        }
    }
}
