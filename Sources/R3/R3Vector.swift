//
//  R3Vector.swift
//  S2Geometry
//
//  Created by Marc Rollin on 4/9/17.
//  Copyright © 2017 Marc Rollin. All rights reserved.
//

import Foundation

/// R3Vector represents a point in ℝ³.
struct R3Vector {
    let x: Double
    let y: Double
    let z: Double

    static let unitEpsilon: Double.Stride = 5e-14
}

// MARK: CustomStringConvertible compliance
extension R3Vector: CustomStringConvertible {

    var description: String {
        return "(\(x.debugDescription), \(y.debugDescription), \(z.debugDescription))"
    }
}

// MARK: Equatable compliance
extension R3Vector: Equatable {

    /// - returns: true iff both vectors have similar x, y and z.
    static func == (lhs: R3Vector, rhs: R3Vector) -> Bool {
        return lhs.x == rhs.x
            && lhs.y == rhs.y
            && lhs.z == rhs.z
    }
}

// MARK: AlmostEquatable compliance
extension R3Vector: AlmostEquatable {

    /// - returns: true if the x, y and z of the two vectors are the same up to the given tolerance.
    static func ==~ (lhs: R3Vector, rhs: R3Vector) -> Bool {
        return abs(lhs.x - rhs.x) < .epsilon
            && abs(lhs.y - rhs.y) < .epsilon
            && abs(lhs.z - rhs.z) < .epsilon
    }
}

// MARK: Comparable compliance
// Two entities are compared element by element with the given operator.
// The first mismatch defines which is less (or greater) than the other.
// If both have equivalent values they are lexicographically equal.
extension R3Vector: Comparable {

    static func < (lhs: R3Vector, rhs: R3Vector) -> Bool {
        if lhs.x != rhs.x {
            return lhs.x < rhs.x
        } else if lhs.y != rhs.y {
            return lhs.y < rhs.y
        }

        return lhs.z < rhs.z
    }

    static func <= (lhs: R3Vector, rhs: R3Vector) -> Bool {
        return lhs == rhs || lhs < rhs
    }

    static func > (lhs: R3Vector, rhs: R3Vector) -> Bool {
        return !(lhs == rhs || lhs < rhs)
    }

    static func >= (lhs: R3Vector, rhs: R3Vector) -> Bool {
        return lhs == rhs || lhs > rhs
    }
}

// MARK: Arithmetic operators
extension R3Vector {

    /// - returns: the standard sum of two vectors.
    static func + (lhs: R3Vector, rhs: R3Vector) -> R3Vector {
        return R3Vector(x: lhs.x + rhs.x, y: lhs.y + rhs.y, z: lhs.z + rhs.z)
    }

    /// - returns: the standard difference of two vectors.
    static func - (lhs: R3Vector, rhs: R3Vector) -> R3Vector {
        return R3Vector(x: lhs.x - rhs.x, y: lhs.y - rhs.y, z: lhs.z - rhs.z)
    }

    /// - returns: the standard scalar product of a vector and a multiplier.
    static func * (lhs: R3Vector, rhs: Double) -> R3Vector {
        return R3Vector(x: lhs.x * rhs,
                        y: lhs.y * rhs,
                        z: lhs.z * rhs)
    }

    static func * (lhs: Double, rhs: R3Vector) -> R3Vector {
        return rhs * lhs
    }

    /// - returns: the scalar division of two points.
    static func / (lhs: R3Vector, rhs: Double) -> R3Vector {
        return lhs * (1 / rhs)
    }
}

// MARK: Instance methods and computed properties
extension R3Vector {

    /// Vector with nonnegative components.
    var absolute: R3Vector {
        return R3Vector(x: abs(x), y: abs(y), z: abs(z))
    }

    /// Vector's normal.
    var normal: Double {
        return sqrt(normal2)
    }

    /// Square of the normal.
    var normal2: Double {
        return dotProduct(with: self)
    }

    /// Unit vector in the same direction.
    var normalized: R3Vector {
        if isEmpty {
            return self
        }

        return self / normal
    }

    /// A unit vector that is orthogonal.
    /// Orthogonal(-v) = -Orthogonal(v).
    var orthogonalized: R3Vector {
        var xx: Double = 0
        var yy: Double = 0
        var zz: Double = 0

        switch largestComponent {
        case .x:
            zz = 1
        case .y:
            xx = 1
        case .z:
            yy = 1
        }

        let other = R3Vector(x: xx, y: yy, z: zz)

        return crossProduct(with: other).normalized
    }

    /// Axis that represents the largest component in this vector.
    var largestComponent: R3Axis {
        let a = absolute

        if a.x > a.y {
            if a.x > a.z {
                return .x
            }

            return .z
        }

        if a.y > a.z {
            return .y
        }

        return .z
    }

    /// Axis that represents the smallest component in this vector.
    var smallestComponent: R3Axis {
        let a = absolute

        if a.x < a.y {
            if a.x < a.z {
                return .x
            }

            return .z
        }

        if a.y < a.z {
            return .y
        }

        return .z
    }

    /// Whether this vector is of approximately unit length.
    var isUnit: Bool {
        return abs(normal2 - 1) <= R3Vector.unitEpsilon
    }

    /// Whether this vector has any non 0 value.
    var isEmpty: Bool {
        return x == 0 && y == 0 && z == 0
    }

    /// - returns: the standard cross product.
    func crossProduct(with other: R3Vector) -> R3Vector {
        return R3Vector(x: y * other.z - z * other.y,
                        y: z * other.x - x * other.z,
                        z: x * other.y - y * other.x)
    }

    /// - returns: the standard dot product of the vector and the other vector.
    func dotProduct(with other: R3Vector) -> Double {
        return x * other.x + y * other.y + z * other.z
    }

    /// - returns: the Euclidean distance with the other vector.
    func distance(to other: R3Vector) -> Double {
        return (self - other).normal
    }

    /// - returns: the angle with the other vector.
    func angle(with other: R3Vector) -> S1Angle {
        return atan2(crossProduct(with: other).normal, dotProduct(with: other))
    }
}
