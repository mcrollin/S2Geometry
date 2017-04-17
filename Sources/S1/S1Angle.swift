//
//  Angle.swift
//  S2Geometry
//
//  Created by Marc Rollin on 4/9/17.
//  Copyright © 2017 Marc Rollin. All rights reserved.
//

import Foundation

// S1Angle represents a 1D angle.
// The major differences from the C++ version are:
//   - no unsigned E5/E6/E7 methods
//   - no S2Point or S2LatLng constructors
//   - no comparison or arithmetic operators
struct S1Angle {
    enum Epsilon: Double {
        case e5 = 1e-5
        case e6 = 1e-6
        case e7 = 1e-7
        case none = 1
    }

    fileprivate static let degrees: Double = 180 / .pi
    fileprivate static let radians: Double = 1 / degrees

    let radians: Double
    var degrees: Double {
        return radians * S1Angle.degrees
    }
}

extension S1Angle: CustomStringConvertible {

    var description: String {
        return "(\(radians))"
    }
}

extension S1Angle: Equatable {

    // Returns true iff both angles have similar value for the same unit.
    static func == (lhs: S1Angle, rhs: S1Angle) -> Bool {
        return lhs.radians == rhs.radians
    }
}

// Two entities are compared element by element with the given operator.
// The first mismatch defines which is less (or greater) than the other.
// If both have equivalent values they are lexicographically equal.
extension S1Angle: Comparable {

    static func < (lhs: S1Angle, rhs: S1Angle) -> Bool {
        return lhs.radians < rhs.radians
    }

    static func <= (lhs: S1Angle, rhs: S1Angle) -> Bool {
        return lhs == rhs || lhs < rhs
    }

    static func > (lhs: S1Angle, rhs: S1Angle) -> Bool {
        return lhs.radians > rhs.radians
    }

    static func >= (lhs: S1Angle, rhs: S1Angle) -> Bool {
        return lhs == rhs || lhs > rhs
    }
}

extension S1Angle {

    static func + (lhs: S1Angle, rhs: S1Angle) -> S1Angle {
        return S1Angle(radians: lhs.radians + rhs.radians)
    }

    static func - (lhs: S1Angle, rhs: S1Angle) -> S1Angle {
        return S1Angle(radians: lhs.radians - rhs.radians)
    }

    static func * (lhs: S1Angle, rhs: Double) -> S1Angle {
        return S1Angle(radians: lhs.radians * rhs)
    }

    static func * (lhs: Double, rhs: S1Angle) -> S1Angle {
        return rhs * lhs
    }

    static func / (lhs: S1Angle, rhs: Double) -> S1Angle {
        return lhs * (1 / rhs)
    }

    // Returns an angle larger than any finite angle.
    static var infinite: S1Angle {
        return S1Angle(degrees: .infinity)
    }

    init(degrees: Double, epsilon: Epsilon = .none) {
        radians = degrees * epsilon.rawValue * S1Angle.radians
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
        return S1Angle(radians: abs(radians))
    }

    // Equivalent angle in [0, 2π).
    var normalized: S1Angle {
        var value = radians.truncatingRemainder(dividingBy: 2 * .pi)

        if value < 0 {
            value += 2 * .pi
        }

        return S1Angle(radians: value)
    }

    // Reports whether this Angle is infinite.
    func isInifinite() -> Bool {
        return radians == .infinity
    }
}
