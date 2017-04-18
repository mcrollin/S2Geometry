//
//  S1ChordAngle.swift
//  S2Geometry
//
//  Created by Marc Rollin on 4/17/17.
//  Copyright © 2017 Marc Rollin. All rights reserved.
//

import Foundation

typealias S1ChordAngle = Double

/// S1ChordAngle represents the angle subtended by a chord
/// (i.e., the straight line segment connecting two points on the sphere).
/// Its representation makes it very efficient for computing and comparing
/// distances, but unlike S1Angle it is only capable of representing angles
/// between 0 and π radians.
/// Generally, S1ChordAngle should only be used in loops where many angles need
/// to be calculated and compared. Otherwise it is simpler to use S1Angle.
///
/// ChordAngle loses some accuracy as the angle approaches π radians.
/// Specifically, the representation of (π - x) radians has an error of about
/// (1e-15 / x), with a maximum error of about 2e-8 radians (about 13cm on the
/// Earth's surface). For comparison, for angles up to π/2 radians (10000km)
/// the worst-case representation error is about 2e-16 radians (1 nanonmeter),
/// which is about the same as S1Angle.
///
/// S1ChordAngles are represented by the squared chord length, which can
/// range from 0 to 4. Positive infinity represents an infinite squared length.

// MARK: Static factories
extension S1ChordAngle {

    /// Chord angle smaller than the zero angle.
    /// The only valid operations on a NegativeChordAngle are comparisons and Angle conversions.
    static let negative: S1ChordAngle = -1

    /// Chord angle of 90 degrees (a "right angle").
    static let right: S1ChordAngle = 2

    /// Chord angle of 180 degrees (a "straight angle").
    /// This is the maximum finite chord angle.
    static let straight: S1ChordAngle = 4

    /// - returns: a S1ChordAngle from the given S1Angle.
    static func angle(_ angle: S1Angle) -> S1ChordAngle {
        if angle < 0 {
            return negative
        } else if angle.isInfinite {
            return infinity
        }

        return pow(2 * sin(0.5 * min(.pi, angle.radians)), 2)
    }

    /// Note that the argument is automatically clamped to a maximum of 4.0 to
    /// handle possible roundoff errors. The argument must be non-negative.
    ///
    /// - returns: a ChordAngle from the squared chord length.
    static func squareLength(_ squareLength: Double) -> S1ChordAngle {
        if squareLength > 4 {
            return straight
        }

        return squareLength
    }

    /// The points must be unit length.
    ///
    /// - returns: a ChordAngle corresponding to the distance between the two given points
    static func betweenPoints(x: S2Point, y: S2Point) -> S1ChordAngle {
        return S1ChordAngle(min(4.0, (x.vector - y.vector).normal2))
    }
}

// MARK: Instance methods and computed properties
extension S1ChordAngle {
    /// The maximum error size for a S1ChordAngle constructed from 2 Points x and y,
    /// assuming that x and y are normalized to within the bounds guaranteed by S2Point.normalized.
    /// The error is defined with respect to the true distance after the points are projected
    /// to lie exactly on the sphere.
    var maxPointError: Double {
        // There is a relative error of (2.5 * epsilon) when computing the squared distance,
        // plus an absolute error of (16 * epsilon^2) because the lengths of the input points
        // may differ from 1 by up to (2 * epsilon) each.
        return self * 2.5 * .epsilon + 16 * pow(.epsilon, 2)
    }

    /// The maximum error for a S1ChordAngle constructed as an S1Angle distance.
    var maxAngleError: Double {
        return self * .epsilon
    }

    var angle: S1Angle {
        if self < 0 {
            return -1
        } else if isInfinite {
            return .infinity
        }
        return 2 * asin(0.5 * sqrt(self))
    }

    /// Sine of this chord angle.
    /// This method is more efficient than converting to S1Angle and performing the computation.
    var sinus: Double {
        return sqrt(sinus2)
    }

    /// Square of the sine of this chord angle.
    /// It is more efficient than sin.
    var sinus2: Double {
        // Let a be the (non-squared) chord length, and let A be the corresponding
        // half-angle (a = 2 * sin(A)).  The formula below can be derived from:
        //   sin(2*A) = 2 * sin(A) * cos(A)
        //   cos^2(A) = 1 - sin^2(A)
        // This is much faster than converting to an angle and computing its sine.
        return self * (1 - 0.25 * self)
    }

    /// The cosine of this chord angle.
    /// This method is more efficient than converting to Angle and performing the computation.
    var cosinus: Double {
        // cos(2*A) = cos^2(A) - sin^2(A) = 1 - 2 * sin^2(A)
        return 1 - 0.5 * self
    }

    /// The tangent of this chord angle.
    var tangent: Double {
        return sinus / cosinus
    }

    /// Whether this ChordAngle is one of the special cases.
    var isSpecial: Bool {
        return self < 0 || isInfinite
    }

    /// Whether this ChordAngle is valid or not.
    var isValid: Bool {
        return (self >= 0 && self <= 4) || isSpecial
    }

    /// Can be positive or negative.
    /// Error should be the value returned by either MaxPointError or MaxAngleError.
    /// For example:
    ///    a := ChordAngleFromPoints(x, y)
    ///    a1 := a.Expanded(a.MaxPointError())
    ///
    /// - returns: a new S1ChordAngle that has been adjusted by the given error bound
    func expanded(errorBound: Double) -> S1ChordAngle {
        // If the angle is special, don't change it. Otherwise clamp it to the valid range.
        if isSpecial {
            return self
        }

        return max(0, min(4, self + errorBound))
    }

    /// Adds the other S1ChordAngle to this one.
    /// This method assumes the S1ChordAngles are not special.
    ///
    /// - returns: the resulting value.
    func add(_ other: S1ChordAngle) -> S1ChordAngle {
        // Note that this method (and sub) is much more efficient than converting
        // the ChordAngle to a S1Angle and adding those and converting back.
        // It requires only one square root plus a few additions and multiplications.

        // Optimization for the common case where b is an error tolerance
        // parameter that happens to be set to zero.
        if other == 0 {
            return self
        }

        // Clamp the angle sum to at most 180 degrees.
        if self + other >= 4 {
            return .straight
        }

        // Let a and b be the (non-squared) chord lengths, and let c = a + b.
        // Let A, B, and C be the corresponding half-angles (a = 2*sin(A), etc).
        // Then the formula below can be derived from c = 2 * sin(A+B) and the
        // relationships   sin(A+B) = sin(A)*cos(B) + sin(B)*cos(A)
        //                 cos(X) = sqrt(1 - sin^2(X))
        let x = self * (1 - 0.25 * other)
        let y = other * (1 - 0.25 * self)

        return min(4.0, x + y + 2 * sqrt(x * y))
    }

    /// Subtracts the other S1ChordAngle from this one.
    /// This method assumes the S1ChordAngles are not special.
    ///
    /// - returns: the resulting value
    func substract(_ other: S1ChordAngle) -> S1ChordAngle {
        if other == 0 {
            return self
        } else if self <= other {
            return 0
        }

        let x = self * (1 - 0.25 * other)
        let y = other * (1 - 0.25 * self)

        return min(4.0, x + y - 2 * sqrt(x * y))
    }
}
