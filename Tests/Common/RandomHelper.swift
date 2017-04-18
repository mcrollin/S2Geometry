//
//  RandomHelper.swift
//  S2Geometry
//
//  Created by Marc Rollin on 4/20/17.
//  Copyright © 2017 Marc Rollin. All rights reserved.
//

import Foundation
@testable import S2Geometry

struct RandomHelper {

    static func double() -> Double {
        return Double(arc4random()) / Double(UInt32.max)
    }

    /// - returns: a uniformly distributed value in the range [min, max).
    static func double(min: Double, max: Double) -> Double {
        return min + double() * (max - min)
    }

    /// - returns: a random unit-length vector.
    static func point() -> S2Point {
        return S2Point.coordinates(x: double(min: -1, max: 1),
                                   y: double(min: -1, max: 1),
                                   z: double(min: -1, max: 1))

    }

    /// - returns: a right-handed coordinate frame (three orthonormal vectors for a randomly generated point.
    static func frame() -> S2Matrix3x3 {
        return frame(at: point())
    }

    /// The x- and y-axes are computed such that (x,y,z) is a right-handed coordinate frame (three orthonormal vectors).
    ///
    /// - returns: a right-handed coordinate frame using the given point as the z-axis.
    static func frame(at z: S2Point) -> S2Matrix3x3 {
        let x = z.crossProduct(with: point()).normalized
        let y = z.crossProduct(with: x).normalized
        let m = S2Matrix3x3()
            .set(column: 0, to: x)
            .set(column: 1, to: y)
            .set(column: 2, to: z)

        return m
    }
}
