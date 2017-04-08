//
//  R2Point.swift
//  S2Geometry
//
//  Created by Marc Rollin on 4/9/17.
//  Copyright © 2017 Marc Rollin. All rights reserved.
//

import Foundation

// R2Point represents a point in ℝ².
struct R2Point {
    let x: Double
    let y: Double
}

extension R2Point: CustomStringConvertible {

    var description: String {
        return "(\(x),\(y))"
    }
}

extension R2Point: Equatable {

    // Returns true iff both points have similar x and y.
    static func == (lhs: R2Point, rhs: R2Point) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y
    }
}

extension R2Point: AlmostEquatable {

    // Returns true if the x and y are the same up to the given tolerance.
    static func ==~ (lhs: R2Point, rhs: R2Point) -> Bool {
        return lhs.x ==~ rhs.x && lhs.y ==~ lhs.y
    }
}

extension R2Point {

    // Returns the sum of two points.
    static func + (lhs: R2Point, rhs: R2Point) -> R2Point {
        return R2Point(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }

    // Returns the difference between two points.
    static func - (lhs: R2Point, rhs: R2Point) -> R2Point {
        return R2Point(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }

    // Returns the scalar product with a Double.
    static func * (lhs: R2Point, rhs: Double) -> R2Point {
        return R2Point(x: lhs.x * rhs, y: lhs.y * rhs)
    }

    static func * (lhs: Double, rhs: R2Point) -> R2Point {
        return rhs * lhs
    }

    // Returns the scalar division of two points.
    static func / (lhs: R2Point, rhs: Double) -> R2Point {
        return lhs * (1 / rhs)
    }

    // The vector's normal.
    var normal: Double {
        return hypot(x, y)
    }

    // A unit point in the same direction.
    var normalized: R2Point {
        if x == 0 && x == 0 {
            return self
        }

        return self / normal
    }

    // Counterclockwise orthogonal point with the same normal.
    var orthogonal: R2Point {
        return R2Point(x: -y, y: x)
    }

    // Returns the dot product with point.
    func dotProduct(with point: R2Point) -> Double {
        return x * point.x + y * point.y
    }

    // Cross product with point.
    func crossProduct(with point: R2Point) -> Double {
        return x * point.y - y * point.x
    }
}
