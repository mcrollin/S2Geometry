//
//  S2Projection.swift
//  S2Geometry
//
//  Created by Marc Rollin on 4/19/17.
//  Copyright © 2017 Marc Rollin. All rights reserved.
//

import Foundation

typealias S2UV = (u: Double, v: Double)
typealias S2FaceUV = (face: Int, u: Double, v: Double)

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
///     - getUNorm, getVNorm, getNorm, getUAxis, getVAxis
extension S2Projection {
    /// In general, tangent produces the most uniform shapes and sizes of cells.
    /// Whereas linear is considerably worse, and quadratic is somewhere in between
    /// (but generally closer to the tangent projection than the linear one).
    /// Taking into account time complexity, quadratic projection offers the best trade-off.
    static let optimal: S2Projection = .quadratic

    /// U, V, and W axes for each face.
    static var faceUVWAxes = [
        [S2Point(x: 0, y: 1, z: 0), S2Point(x: 0, y: 0, z: 1), S2Point(x: 1, y: 0, z: 0)],
        [S2Point(x: -1, y: 0, z: 0), S2Point(x: 0, y: 0, z: 1), S2Point(x: 0, y: 1, z: 0)],
        [S2Point(x: -1, y: 0, z: 0), S2Point(x: 0, y: -1, z: 0), S2Point(x: 0, y: 0, z: 1)],
        [S2Point(x: 0, y: 0, z: -1), S2Point(x: 0, y: -1, z: 0), S2Point(x: -1, y: 0, z: 0)],
        [S2Point(x: 0, y: 0, z: -1), S2Point(x: 1, y: 0, z: 0), S2Point(x: 0, y: -1, z: 0)],
        [S2Point(x: 0, y: 1, z: 0), S2Point(x: 1, y: 0, z: 0), S2Point(x: 0, y: 0, z: -1)]
    ]

    /// Precomputed neighbors of each face.
    static var faceUVWFaces = [
        [[4, 1], [5, 2], [3, 0]],
        [[0, 3], [5, 2], [4, 1]],
        [[0, 3], [1, 4], [5, 2]],
        [[2, 5], [1, 4], [0, 3]],
        [[2, 5], [3, 0], [1, 4]],
        [[4, 1], [3, 0], [2, 5]]
    ]

    /// Converts an s or t value to the corresponding u or v value.
    /// This is a non-linear transformation from [-1,1] to [-1,1] that attempts to make the cell sizes more uniform.
    ///
    /// - returns: The corresponding u or v value.
    func uv(st: Double) -> Double {
        switch self {
        case .linear:
            return 2 * st - 1
        case .tangent:
            let st = tan(.pi / 2 * st - .pi / 4)

            return st + (1 / Double(UInt64(1) << 53)) * st
        case .quadratic:
            if st >= 0.5 {
                return (1 / 3.0) * (4 * pow(st, 2) - 1)
            }

            return (1 / 3.0) * (1 - 4 * pow(1 - st, 2))
        }
    }

    /// Inverse of the stToUV transformation.
    /// Note that it is not always true that uvToST(stToUV(x)) == x due to numerical errors.
    ///
    /// - returns: The corresponding s or t value.
    func st(uv: Double) -> Double {
        switch self {
        case .linear:
            return 0.5 * (uv + 1)
        case .tangent:
            let a = atan(uv)

            return (2 / .pi) * (a + .pi / 4)
        case .quadratic:
            if uv >= 0 {
                return 0.5 * sqrt(1 + 3 * uv)
            }

            return 1 - 0.5 * sqrt(1 - 3 * uv)
        }
    }

    /// For points on the boundary between faces, the result is arbitrary but deterministic.
    ///
    /// - returns: face from 0 to 5 containing xyz.
    func face(xyz: XYZPositionable) -> Int {
        var id: Int = 0
        var value = xyz.x

        if abs(xyz.y) > abs(xyz.x) {
            id = 1
            value = xyz.y
        }

        if abs(xyz.z) > abs(value) {
            id = 2
            value = xyz.z
        }

        if value < 0 {
            id += 3
        }

        return id
    }

    /// Given a valid face for the given point (meaning that dot product of r with the face normal is positive).
    ///
    /// - returns: the corresponding u and v values, which may lie outside the range [-1,1].
    func uv(validFace face: Int, xyz: XYZPositionable) -> S2UV {
        assert(0 ..< S2CellIdentifier.facesCount ~= face)

        switch face {
        case 0:
            return S2UV(u: xyz.y / xyz.x, v: xyz.z / xyz.x)
        case 1:
            return S2UV(u: -xyz.x / xyz.y, v: xyz.z / xyz.y)
        case 2:
            return S2UV(u: -xyz.x / xyz.z, v: -xyz.y / xyz.z)
        case 3:
            return S2UV(u: xyz.z / xyz.x, v: xyz.y / xyz.x)
        case 4:
            return S2UV(u: xyz.z / xyz.y, v: -xyz.x / xyz.y)
        default:
            return S2UV(u: -xyz.y / xyz.z, v: -xyz.x / xyz.z)
        }
    }

    /// Converts a xyz position (not necessarily unit length) to (face, u, v) coordinates.
    func faceUV(xyz: XYZPositionable) -> S2FaceUV {
        let validFace = face(xyz: xyz)
        let (u, v) = uv(validFace: validFace, xyz: xyz)

        return S2FaceUV(face: validFace, u: u, v: v)
    }

    /// Turns face and UV coordinates into an unnormalized point.
    func xyz(face: Int, u: Double, v: Double) -> S2Point {
        assert(0 ..< S2CellIdentifier.facesCount ~= face)

        switch face {
        case 0:
            return S2Point(x: 1, y: u, z: v)
        case 1:
            return S2Point(x: -u, y: 1, z: v)
        case 2:
            return S2Point(x: -u, y: -v, z: 1)
        case 3:
            return S2Point(x: -1, y: -v, z: -u)
        case 4:
            return S2Point(x: v, y: -1, z: -u)
        default:
            return S2Point(x: v, y: u, z: -1)
        }
    }

    /// Only if the dot product of the point with the given face normal is positive.
    ///
    /// - returns: the u and v values (which may lie outside the range [-1, 1]).
    func uv(face: Int, xyz: XYZPositionable) -> S2UV? {
        assert(0 ..< S2CellIdentifier.facesCount ~= face)

        switch face {
        case 0 where xyz.x <= 0:
            return nil
        case 1 where xyz.y <= 0:
            return nil
        case 2 where xyz.z <= 0:
            return nil
        case 3 where xyz.x >= 0:
            return nil
        case 4 where xyz.y >= 0:
            return nil
        case 5 where xyz.z >= 0:
            return nil
        default:
            return uv(validFace: face, xyz: xyz)
        }
    }

    /// Transforms the given xyz to a point in (u,v,w) coordinate frame of the given
    /// face where the w-axis represents the face normal.
    func uvw(face: Int, xyz: XYZPositionable) -> S2Point {
        assert(0 ..< S2CellIdentifier.facesCount ~= face)

        // The result coordinates are simply the dot products of xyz with the (u,v,w)
        // axes for the given face (see faceUVWAxes).
        switch face {
        case 0:
            return S2Point(x: xyz.y, y: xyz.z, z: xyz.x)
        case 1:
            return S2Point(x: -xyz.x, y: xyz.z, z: xyz.y)
        case 2:
            return S2Point(x: -xyz.x, y: -xyz.y, z: xyz.z)
        case 3:
            return S2Point(x: -xyz.z, y: -xyz.y, z: -xyz.x)
        case 4:
            return S2Point(x: -xyz.z, y: xyz.x, z: -xyz.y)
        default:
            return S2Point(x: xyz.y, y: xyz.x, z: -xyz.z)
        }
    }

    /// For an edge in the direction of the positive v-axis at the given u-value on the given face.
    /// (This vector is perpendicular to the plane through the sphere origin that contains the given edge.)
    ///
    /// - returns: the right-handed normal (not necessarily unit length).
    func uNormal(face: Int, u: Double) -> R3Vector {
        assert(0 ..< S2CellIdentifier.facesCount ~= face)

        switch face {
        case 0:
            return R3Vector(x: u, y: -1, z: 0)
        case 1:
            return R3Vector(x: 1, y: u, z: 0)
        case 2:
            return R3Vector(x: 1, y: 0, z: u)
        case 3:
            return R3Vector(x: -u, y: 0, z: 1)
        case 4:
            return R3Vector(x: 0, y: -u, z: 1)
        default:
            return R3Vector(x: 0, y: -1, z: -u)
        }
    }

    /// For an edge in the direction of the positive u-axis at the given v-value on the given face.
    ///
    /// - returns: the right-handed normal (not necessarily unit length).
    func vNormal(face: Int, v: Double) -> R3Vector {
        assert(0 ..< S2CellIdentifier.facesCount ~= face)

        switch face {
        case 0:
            return R3Vector(x: -v, y: 0, z: 1)
        case 1:
            return R3Vector(x: 0, y: -v, z: 1)
        case 2:
            return R3Vector(x: 0, y: -1, z: -v)
        case 3:
            return R3Vector(x: v, y: -1, z: 0)
        case 4:
            return R3Vector(x: 1, y: v, z: 0)
        default:
            return R3Vector(x: 1, y: 0, z: v)
        }
    }

    /// - returns: the given axis of the given face.
    func uvwAxis(face: Int, axis: Int) -> S2Point {
        assert(0 ..< S2CellIdentifier.facesCount ~= face)
        assert(0 ... 3 ~= axis)

        return S2Projection.faceUVWAxes[face][axis]
    }

    /// - returns: the face in the (u,v,w) coordinate system on the given axis in the given direction.
    func uvwFace(face: Int, axis: Int, direction: Int) -> Int {
        assert(0 ..< S2CellIdentifier.facesCount ~= face)
        assert(0 ... 3 ~= axis)
        assert(0 ... 1 ~= direction)

        return S2Projection.faceUVWFaces[face][axis][direction]
    }

    /// - returns: the u-axis for the given face.
    func uAxis(face: Int) -> S2Point {
        assert(0 ..< S2CellIdentifier.facesCount ~= face)

        return uvwAxis(face: face, axis: 0)
    }

    /// - returns: the v-axis for the given face.
    func vAxis(face: Int) -> S2Point {
        assert(0 ..< S2CellIdentifier.facesCount ~= face)

        return uvwAxis(face: face, axis: 1)
    }

    /// - returns: the unit-length normal for the given face.
    func unitNormal(face: Int) -> S2Point {
        assert(0 ..< S2CellIdentifier.facesCount ~= face)

        return uvwAxis(face: face, axis: 2)
    }
}
