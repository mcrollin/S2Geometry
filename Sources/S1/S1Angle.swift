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
    enum Unit: CustomStringConvertible {
        case degrees, radians

        var description: String {
            switch self {
            case .degrees:
                return "deg"
            case .radians:
                return "rad"
            }
        }
    }

    enum Epsilon: Double {
        case e5 = 1e-5
        case e6 = 1e-6
        case e7 = 1e-7
        case none = 1
    }

    let value: Double
    let unit: Unit

    fileprivate static let degrees: Double = 180 / .pi
    fileprivate static let radians: Double = 1 / degrees
}

extension S1Angle: CustomStringConvertible {

    var description: String {
        return "(\(value) \(unit))"
    }
}

extension S1Angle: Equatable {

    // Returns true iff both angles have similar value for the same unit.
    static func == (lhs: S1Angle, rhs: S1Angle) -> Bool {
        if lhs.unit == rhs.unit {
            return lhs.value == rhs.value
        }

        return lhs.radians == rhs.radians
    }
}

extension S1Angle {

    // Returns an angle larger than any finite angle.
    static var infinite: S1Angle {
        return S1Angle(degrees: .infinity)
    }

    init(degrees: Double, epsilon: Epsilon = .none) {
        value = degrees * epsilon.rawValue
        unit = .degrees
    }

    init(radians: Double) {
        value = radians
        unit = .radians
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
        return S1Angle(value: abs(value), unit: unit)
    }

    // Equivalent angle in [0, 2π).
    var normalized: S1Angle {
        var r = radians.truncatingRemainder(dividingBy: 2 * .pi)

        if r < 0 {
            r += 2 * .pi
        }

        return S1Angle(value: r, unit: .radians)
    }

    // In degrees.
    var degrees: Double {
        return unit == .degrees ? value : (value * S1Angle.degrees)
    }

    // In radians.
    var radians: Double {
        return unit == .radians ? value : (value * S1Angle.radians)
    }

    // Angle converted to given unit.
    func converted(to unit: Unit) -> S1Angle {
        switch unit {
        case .degrees:
            return S1Angle(degrees: degrees)
        case .radians:
            return S1Angle(radians: radians)
        }
    }

    // Reports whether this Angle is infinite.
    func isInifinite() -> Bool {
        return value == .infinity
    }
}
