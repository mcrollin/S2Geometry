//
//  S1Interval.swift
//  S2Geometry
//
//  Created by Marc Rollin on 4/11/17.
//  Copyright © 2017 Marc Rollin. All rights reserved.
//

import Foundation

// S1Interval represents a closed interval on a unit circle.
// Zero-length intervals (where low == high) represent single points.
// If low > high then the interval is "inverted".
// The point at (-1, 0) on the unit circle has two valid representations,
// [π,π] and [-π,-π]. We normalize the latter to the former in IntervalFromEndpoints.
// There are two special intervals that take advantage of that:
//   - the full interval, [-π,π], and
//   - the empty interval, [π,-π].
// Treat the exported fields as read-only.
struct S1Interval {
    let low: Double
    let high: Double

    // Constructs a new interval from endpoints.
    // Both arguments must be in the range [-π,π].
    // This function allows inverted intervals to be created.
    init(low: Double, high: Double) {
        var ll = low
        var hh = high

        if low == -.pi && high != .pi {
            ll = .pi
        }

        if high == -.pi && low != .pi {
            hh = .pi
        }

        self.low = ll
        self.high = hh
    }
}

fileprivate extension S1Interval {

    init(unboundedLow: Double, unboundedHigh: Double) {
        low = unboundedLow
        high = unboundedHigh
    }
}

extension S1Interval {

    var complementCenter: Double {
        if low != high {
            return complement.center
        }

        return high <= 0 ? high + .pi : high - .pi
    }

    var complement: S1Interval {
        if low == high {
            return .full
        }

        return inverted
    }

    // Computes distance from a to b in [0,2π], in a numerically stable way.
    static func positiveDistance(from pointA: Double, to pointB: Double) -> Double {
        let distance = pointB - pointA

        if distance >= 0 {
            return distance
        }

        // We want to ensure that if b == pi and a == (-pi + eps),
        // the return result is approximately 2 * pi and not zero.
        return (pointB + .pi) - (pointA - .pi)
    }

    // Expands the interval to include the other interval.
    // This is the same as replacing the interval by the union of the two interval.
    static func + (lhs: S1Interval, rhs: S1Interval) -> S1Interval {
        return lhs.union(with: rhs)
    }

    // Constructs the minimal interval containing the two given points.
    // Both arguments must be in [-π,π].
    init(pointA: Double, pointB: Double) {
        var a = pointA
        var b = pointB

        if pointA == -.pi {
            a = .pi
        }

        if pointB == -.pi {
            b = .pi
        }

        if S1Interval.positiveDistance(from: a, to: b) <= .pi {
            self.low = a
            self.high = b
        } else {
            self.low = b
            self.high = a
        }
    }

    // Empty interval.
    static var empty: S1Interval {
        return S1Interval(unboundedLow: .pi, unboundedHigh: -.pi)
    }

    // Full interval.
    static var full: S1Interval {
        return S1Interval(unboundedLow: -.pi, unboundedHigh: .pi)
    }

    // Interval with endpoints swapped.
    var inverted: S1Interval {
        return S1Interval(unboundedLow: high, unboundedHigh: low)
    }

    // Reports whether the interval is valid.
    func isValid() -> Bool {
        return abs(low) <= .pi && abs(high) <= .pi
            && !(low == -.pi && high != .pi)
            && !(high == -.pi && low != .pi)
    }

    // Reports whether the interval is full.
    func isFull() -> Bool {
        return low == -.pi && high == .pi
    }

    // Reports whether the interval is inverted; that is, whether low > high.
    func isInverted() -> Bool {
        return low > high
    }

    // Assumes that the point ∈ (-π,π].
    func fastContains(point: Double) -> Bool {
        if isInverted() {
            return (point >= low || point <= high) && !isEmpty()
        }

        return point >= low && point <= high
    }

    // Distance realized by either two high endpoints or two low endpoints, whichever is farther apart.
    func directedHausdorffDistance(with other: S1Interval) -> Double {
        // Also includes the case is interval is empty
        if other.contains(interval: self) {
            return 0
        } else if other.isEmpty() {
            return .pi // Maximum possible distance on S1
        }

        let otherComplementCenter = other.complementCenter

        if contains(point: otherComplementCenter) {
            return S1Interval.positiveDistance(from: other.high, to: otherComplementCenter)
        } else {
            let hh = S1Interval(low: other.high, high: otherComplementCenter).contains(point: high)
                ? S1Interval.positiveDistance(from: other.high, to: high) : 0
            let ll = S1Interval(low: otherComplementCenter, high: other.low).contains(point: low)
                ? S1Interval.positiveDistance(from: low, to: other.low) : 0

            return max(hh, ll)
        }
    }
}
