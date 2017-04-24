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

    /// - returns: a uniformly distributed value in the range [min, max).
    static func int(_ lower: Int = .min, _ upper: Int = .max) -> Int {
        return lower + Int(arc4random_uniform(UInt32(upper - lower)))
    }

    /// - returns: a uniformly distributed value in the range [min, max).
    static func uint32(_ lower: UInt32 = .min, _ upper: UInt32 = .max) -> UInt32 {
        return lower + arc4random_uniform(upper - lower)
    }

    /// cf: https://stackoverflow.com/questions/26549830/swift-random-number-for-64-bit-integers/43020440
    static func uint64(_ lower: UInt64 = .min, _ upper: UInt64 = .max) -> UInt64 {
        let range = UInt64.max - UInt64.max % upper
        var rnd: UInt64 = 0

        repeat {
            arc4random_buf(&rnd, MemoryLayout.size(ofValue: rnd))
        } while rnd >= range

        return lower + rnd % (upper - lower)
    }

    /// - returns: a uniformly distributed value in the range [min, max).
    static func double(_ lower: Double = 0, _ upper: Double = 1) -> Double {
        return lower + drand48() * (upper - lower)
    }

    /// - returns: a random unit-length vector.
    static func point() -> S2Point {
        return S2Point.coordinates(x: double(-1, 1),
                                   y: double(-1, 1),
                                   z: double(-1, 1))
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

    // randomCellIDForLevel returns a random CellID at the given level.
    // The distribution is uniform over the space of cell ids, but only
    // approximately uniform over the surface of the sphere.
    static func cellIdentifier(level: Int) -> S2CellIdentifier {
        let face = RandomHelper.int(0, S2CellIdentifier.facesCount - 1)
        let position = RandomHelper.uint64() & UInt64((1 << S2CellIdentifier.positionBits) - 1)

        return S2CellIdentifier(face: face, position: position, level: level)
    }

    static func cellIdentifier() -> S2CellIdentifier {
        return cellIdentifier(level: int(0, S2CellIdentifier.maxLevel))
    }
}
