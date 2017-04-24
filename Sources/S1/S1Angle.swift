//
//  S1Angle.swift
//  S2Geometry
//
//  Created by Marc Rollin on 4/9/17.
//  Copyright © 2017 Marc Rollin. All rights reserved.
//

import Foundation

typealias S1Angle = Double
private let toDegrees: Double = 180 / .pi
private let toRadians: Double = 1 / toDegrees

/// S1Angle represents a 1D angle.
/// The major differences from the C++ version are:
///   - no unsigned E5/E6/E7 methods
///   - no S2Point or S2LatLng constructors
///   - no comparison or arithmetic operators

// MARK: Static factories
extension S1Angle {

    static func degrees(_ degrees: Double, epsilon: Epsilon = .none) -> S1Angle {
        return degrees * epsilon.rawValue * toRadians
    }

    static func radians(_ radians: Double) -> S1Angle {
        return radians
    }
}

// MARK: Instance methods and computed properties
extension S1Angle {

    enum Epsilon: Double {
        case e5 = 1e-5
        case e6 = 1e-6
        case e7 = 1e-7
        case none = 1
    }

    var radians: Double {
        return self
    }

    var degrees: Double {
        return self * toDegrees
    }

    // In hundred thousandths of degrees.
    var epsilon5: Int {
        return lround(degrees * 1e5)
    }

    // In millionths of degrees.
    var epsilon6: Int {
        return lround(degrees * 1e6)
    }

    // In ten millionths of degrees.
    var epsilon7: Int {
        return lround(degrees * 1e7)
    }

    // Absolute value of the angle.
    var absolute: S1Angle {
        return abs(radians)
    }

    // Equivalent angle in [0, 2π).
    var normalized: S1Angle {
        var value = radians.remainder(dividingBy: 2 * .pi)

        if value < 0 {
            value += 2 * .pi
        }

        return value
    }
}
