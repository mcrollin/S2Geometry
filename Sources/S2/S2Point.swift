//
//  S2Point.swift
//  S2Geometry
//
//  Created by Marc Rollin on 4/18/17.
//  Copyright © 2017 Marc Rollin. All rights reserved.
//

import Foundation

/// Point represents a point on the unit sphere as a normalized 3D vector.
///
/// - todo: Missing methods
///     - orderedCounterClockwise
///     - capBound, rectBound
///     - containsCell, intersectsCell
///     - rotate, angle, turnAngle
///     - signedArea
struct S2Point {
    let vector: R3Vector
}

// MARK: Equatable compliance
extension S2Point: Equatable {

    /// - returns: True iff both points have similar x, y and z.
    static func == (lhs: S2Point, rhs: S2Point) -> Bool {
        return lhs.x == rhs.x
            && lhs.y == rhs.y
            && lhs.z == rhs.z
    }
}

// MARK: AlmostEquatable compliance
extension S2Point: AlmostEquatable {

    /// - returns: Whether the two points are similar enough to be equal.
    static func ==~ (lhs: S2Point, rhs: S2Point) -> Bool {
        return lhs.distance(with: rhs) <= S1Angle(.epsilon)
    }
}

// MARK: Static factories and Arithmetic operators
extension S2Point {

    /// Unique "origin" on the sphere for operations that need a fixed
    /// reference point.
    /// In particular, this is the "point at infinity" used for
    /// point-in-polygon testing (by counting the number of edge crossings).
    ///
    /// It should *not* be a point that is commonly used in edge tests in order
    /// to avoid triggering code to handle degenerate cases (this rules out the
    /// north and south poles). It should also not be on the boundary of any
    /// low-level S2Cell for the same reason.
    static let origin = S2Point(vector: R3Vector(x: -0.0099994664350250197,
                                                 y: 0.0025924542609324121,
                                                 z: 0.99994664350250195))

    /// This always returns a valid point.
    /// If the given coordinates can not be normalized the origin point will be returned.
    ///
    /// This behavior is different from the C++ construction of a S2Point from coordinates:
    /// (i.e. S2Point(x, y, z)) in that in C++ they do not Normalize.
    ///
    /// - returns: Creates a new normalized point from coordinates.
    static func coordinates(x: Double, y: Double, z: Double) -> S2Point {
        if x == 0 && y == 0 && z == 0 {
            return origin
        }

        return S2Point(vector: R3Vector(x: x, y: y, z: z).normalized)
    }

    /// The result is not normalized.
    /// The reasons for multiplying by the signed area are (1) this is the quantity
    /// that needs to be summed to compute the centroid of a union or difference of triangles,
    /// and (2) it's actually easier to calculate this way. All points must have unit length.
    ///
    /// The true centroid (mass centroid) is defined as the surface integral
    // over the spherical triangle of (x,y,z) divided by the triangle area.
    /// This is the point that the triangle would rotate around if it was
    /// spinning in empty space.
    ///
    /// The best centroid for most purposes is the true centroid. Unlike the
    /// planar and surface centroids, the true centroid behaves linearly as
    /// regions are added or subtracted. That is, if you split a triangle into
    /// pieces and compute the average of their centroids (weighted by triangle
    /// area), the result equals the centroid of the original triangle. This is
    /// not true of the other centroids.
    ///
    /// - returns: The true centroid of the spherical triangle ABC multiplied by its signed area.
    static func trueCentroid(a: S2Point, b: S2Point, c: S2Point) -> S2Point {
        let sa = b.distance(with: c)
        let sb = c.distance(with: a)
        let sc = a.distance(with: b)
        let ra = sa != 0 ? sa / sin(sa) : 1
        let rb = sb != 0 ? sb / sin(sb) : 1
        let rc = sc != 0 ? sc / sin(sc) : 1

        // Now compute a point M such that:
        //
        //  [Ax Ay Az] [Mx]                       [ra]
        //  [Bx By Bz] [My]  = 0.5 * det(A,B,C) * [rb]
        //  [Cx Cy Cz] [Mz]                       [rc]
        //
        // To improve the numerical stability we subtract the first row (A) from the
        // other two rows; this reduces the cancellation error when A, B, and C are
        // very close together. Then we solve it using Cramer's rule.
        //
        // This code still isn't as numerically stable as it could be.
        // The biggest potential improvement is to compute B-A and C-A more
        // accurately so that (B-A)x(C-A) is always inside triangle ABC.
        let x = R3Vector(x: a.x, y: b.x - a.x, z: c.x - a.x)
        let y = R3Vector(x: a.y, y: b.y - a.y, z: c.y - a.y)
        let z = R3Vector(x: a.z, y: b.z - a.z, z: c.z - a.z)
        let r = R3Vector(x: ra, y: rb - ra, z: rc - ra)

        return S2Point(x: y.crossProduct(with: z).dotProduct(with: r),
                       y: z.crossProduct(with: x).dotProduct(with: r),
                       z: x.crossProduct(with: y).dotProduct(with: r))
    }

    /// It can be normalized to unit length to obtain the "surface centroid" of the corresponding
    /// spherical triangle, i.e. the intersection of the three medians. However,
    /// note that for large spherical triangles the surface centroid may be
    /// nowhere near the intuitive "center" (see example in TrueCentroid comments).
    ///
    /// Note that the surface centroid may be nowhere near the intuitive
    /// "center" of a spherical triangle. For example, consider the triangle
    /// with vertices A=(1,eps,0), B=(0,0,1), C=(-1,eps,0) (a quarter-sphere).
    /// The surface centroid of this triangle is at S=(0, 2*eps, 1), which is
    /// within a distance of 2*eps of the vertex B. Note that the median from A
    /// (the segment connecting A to the midpoint of BC) passes through S, since
    /// this is the shortest path connecting the two endpoints. On the other
    /// hand, the true centroid is at M=(0, 0.5, 0.5), which when projected onto
    /// the surface is a much more reasonable interpretation of the "center" of
    /// this triangle.
    ///
    /// - returns: The centroid of the planar triangle ABC, which is not normalized.
    static func planarCentroid(a: S2Point, b: S2Point, c: S2Point) -> S2Point {
        return S2Point(vector: (a.vector + b.vector + c.vector) / 3)
    }

    /// This method is based on l'Huilier's theorem,
    ///
    ///     tan(E/4) = sqrt(tan(s/2) tan((s-a)/2) tan((s-b)/2) tan((s-c)/2))
    ///
    /// where E is the spherical excess of the triangle (i.e. its area),
    ///       a, b, c are the side lengths, and
    ///       s is the semiperimeter (a + b + c) / 2.
    ///
    /// The only significant source of error using l'Huilier's method is the
    /// cancellation error of the terms (s-a), (s-b), (s-c). This leads to a
    /// *relative* error of about 1e-16 * s / min(s-a, s-b, s-c). This compares
    /// to a relative error of about 1e-15 / E using Girard's formula, where E is
    /// the true area of the triangle. Girard's formula can be even worse than
    /// this for very small triangles, e.g. a triangle with a true area of 1e-30
    /// might evaluate to 1e-5.
    ///
    /// So, we prefer l'Huilier's formula unless dmin < s * (0.1 * E), where
    /// dmin = min(s-a, s-b, s-c). This basically includes all triangles
    /// except for extremely long and skinny ones.
    ///
    /// Since we don't know E, we would like a conservative upper bound on
    /// the triangle area in terms of s and dmin. It's possible to show that
    /// E <= k1 * s * sqrt(s * dmin), where k1 = 2*sqrt(3)/Pi (about 1).
    /// Using this, it's easy to show that we should always use l'Huilier's
    /// method if dmin >= k2 * s^5, where k2 is about 1e-2. Furthermore,
    /// if dmin < k2 * s^5, the triangle area is at most k3 * s^4, where
    /// k3 is about 0.1. Since the best case error using Girard's formula
    /// is about 1e-15, this means that we shouldn't even consider it unless
    /// s >= 3e-4 or so.
    ///
    /// - returns: The area on the unit sphere for the triangle defined by the given points.
    static func area(a: S2Point, b: S2Point, c: S2Point) -> Double {
        let sa = b.vector.angle(with: c.vector)
        let sb = c.vector.angle(with: a.vector)
        let sc = a.vector.angle(with: b.vector)
        let s = 0.5 * (sa + sb + sc)

        if s >= 3e-4 {
            // Consider whether Girard's formula might be more accurate.
            let dmin = s - max(sa, max(sb, sc))

            if dmin < 1e-2 * pow(s, 5) {
                // This triangle is skinny enough to use Girard's formula.
                let ab = a.pointCrossProduct(with: b)
                let bc = b.pointCrossProduct(with: c)
                let ac = a.pointCrossProduct(with: c)
                let area = max(0.0, ab.vector.angle(with: ac.vector)
                    - ab.vector.angle(with: bc.vector) + bc.vector.angle(with: ac.vector))

                if dmin < s * 0.1 * area {
                    return area
                }
            }
        }

        let squareTan = tan(0.5 * s) * tan(0.5 * (s - sa)) * tan(0.5 * (s - sb)) * tan(0.5 * (s - sc))

        // Use l'Huilier's formula.
        return 4 * atan(sqrt(max(0.0, squareTan)))
    }

    /// All vertices are located on a circle of the specified angular radius around the center.
    /// The radius is the actual distance from center to each vertex.
    ///
    /// - returns: A slice of points shaped as a regular polygon with verticesCount vertices.
    static func regularPoints(center: S2Point, radius: S1Angle, verticesCount: Int) -> [S2Point] {
        return regularPoints(for: center.frame, radius: radius, verticesCount: verticesCount)
    }

    /// All vertices are located on a circle of the specified angular radius around the center.
    /// The radius is the actual distance from the center to each vertex.
    ///
    /// - returns: A slice of points shaped as a regular polygon with verticesCount vertices.
    static func regularPoints(for frame: S2Matrix3x3, radius: S1Angle, verticesCount: Int) -> [S2Point] {
        // We construct the loop in the given frame coordinates, with the center at
        // (0, 0, 1). For a loop of radius r, the loop vertices have the form
        // (x, y, z) where x^2 + y^2 = sin(r) and z = cos(r). The distance on the
        // sphere (arc length) from each vertex to the center is acos(cos(r)) = r.
        let z = cos(radius.radians)
        let r = sin(radius.radians)
        let radianStep = 2 * .pi / Double(verticesCount)

        var vertices = [S2Point]()

        for index in 0..<verticesCount {
            let angle = Double(index) * radianStep
            let point = S2Point(x: r * cos(angle), y: r * sin(angle), z: z)
            let vertex = S2Point.from(frame: frame, point: point)

            vertices.append(S2Point(vector: vertex.vector.normalized))
        }

        return vertices
    }

    /// The resulting point q satisfies the identity (frame * q == p).
    ///
    /// - returns: the coordinates of the given point with respect to its orthonormal basis frame.
    static func to(frame: S2Matrix3x3, point p: S2Point) -> S2Point {
        // The inverse of an orthonormal matrix is its transpose.
        return frame.transposed * p
    }

    /// The resulting point point satisfies the identity (p == frame * q).
    ///
    /// - returns: The coordinates of the given point in standard axis-aligned basis from its orthonormal basis frame.
    static func from(frame: S2Matrix3x3, point q: S2Point) -> S2Point {
        return frame * q
    }

    /// - returns: the standard sum of two points.
    static func + (lhs: S2Point, rhs: S2Point) -> S2Point {
        return S2Point(vector: lhs.vector + rhs.vector)
    }

    /// - returns: the standard difference of two points.
    static func - (lhs: S2Point, rhs: S2Point) -> S2Point {
        return S2Point(vector: lhs.vector - rhs.vector)
    }

    /// - returns: the standard scalar product of a point and a multiplier.
    static func * (lhs: S2Point, rhs: Double) -> S2Point {
        return S2Point(vector: lhs.vector * rhs)
    }

    static func * (lhs: Double, rhs: S2Point) -> S2Point {
        return rhs * lhs
    }
}

// MARK: Instance methods and computed properties
extension S2Point {

    var x: Double { return vector.x }
    var y: Double { return vector.y }
    var z: Double { return vector.z }
    var isUnit: Bool { return vector.isUnit }
    var normal: Double { return vector.normal }

    var orthogonalized: S2Point {
        return S2Point(vector: vector.orthogonalized)
    }

    var normalized: S2Point {
        return S2Point(vector: vector.normalized)
    }

    /// The orthonormal frame for the given point on the unit sphere.
    var frame: S2Matrix3x3 {
        // Given the point p on the unit sphere, extend this into a right-handed
        // coordinate frame of unit-length column vectors m = (x,y,z).  Note that
        // the vectors (x,y) are an orthonormal frame for the tangent space at point p,
        // while p itself is an orthonormal frame for the normal space at p.

        let matrix = S2Matrix3x3()
            .set(column: 2, to: self)
            .set(column: 1, to: orthogonalized)

        return matrix.set(column: 0, to: matrix.column(1).crossProduct(with: self))
    }

    init(x: Double, y: Double, z: Double) {
        vector = R3Vector(x: x, y: y, z: z)
    }

    /// - parameter other: The other point used to compute the distance.
    /// - returns: the angle between two points.
    func distance(with other: S2Point) -> S1Angle {
        return vector.angle(with: other.vector)
    }

    func crossProduct(with other: S2Point) -> S2Point {
        return S2Point(vector: vector.crossProduct(with: other.vector))
    }

    func dotProduct(with other: S2Point) -> Double {
        return vector.dotProduct(with: other.vector)
    }

    /// This is similar to `point.crossProduct(other)` (the true cross product)
    /// except that it does a better job of ensuring orthogonality when the point
    /// is nearly parallel to other, it returns a non-zero result even
    /// when `point == other` or `point == -other` and the result is a Point.
    ///
    /// It satisfies the following properties (`f == pointCrossProduct`):
    ///
    ///     (1) f(point, other) != 0 for all point, other
    ///     (2) f(other, point) == -f(point, other) unless point == other or point == -other
    ///     (3) f(-point , other) == -f(point, other) unless point == other or point == -other
    ///     (4) f(point, -other) == -f(point, other) unless point == other or point == -other
    ///
    /// - parameter other: The other point to which the return point is orthogonal.
    /// - returns: A Point that is orthogonal to both point and other.
    func pointCrossProduct(with other: S2Point) -> S2Point {
        // In the C++ API the equivalent method here was known as "RobustCrossProd",
        // but pointCrossProduct more accurately describes how this method is used.
        let resultingVector = (vector + other.vector).crossProduct(with: other.vector - vector)

        if resultingVector.isEmpty {
            // The only result that makes sense mathematically is to return zero,
            // but we find it more convenient to return an arbitrary orthogonal vector.
            return orthogonalized
        }

        return S2Point(vector: resultingVector)
    }

    /// - returns: True if this point contains the other point.
    func contains(point other: S2Point) -> Bool {
        return self == other
    }
}
