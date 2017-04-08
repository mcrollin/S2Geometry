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
}

fileprivate extension S1Interval {

    // Computes distance from a to b in [0,2π], in a numerically stable way.
    static func positiveDistance(from pointA: Double, to pointB: Double) -> Double {
        let distance = pointB - pointA

        if distance >= 0 {
            return distance
        }

        return (pointB + .pi) - (pointA - .pi)
    }
}

extension S1Interval {

    // Constructs a new interval from endpoints.
    // Both arguments must be in the range [-π,π].
    // This function allows inverted intervals to be created.
    init(low: Double, high: Double, checked: Bool = true) {
        var ll = low
        var hh = high

        if !checked {
            if low == -.pi && high != .pi {
                ll = .pi
            }

            if high == -.pi && low != .pi {
                hh = .pi
            }
        }

        self.low = ll
        self.high = hh
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
        return S1Interval(low: .pi, high: -.pi)
    }

    // Full interval.
    static var full: S1Interval {
        return S1Interval(low: -.pi, high: .pi)
    }

    // Interval with endpoints swapped.
    var inverted: S1Interval {
        return S1Interval(low: high, high: low)
    }

    // Midpoint of the interval.
    // It is undefined for full and empty intervals.
    var center: Double {
        let center = 0.5 * (low + high)

        if isInverted() {
            return center
        } else if center <= 0 {
            return center + .pi
        }

        return center - .pi
    }

    // Length of the interval.
    // The length of an empty interval is negative.
    var length: Double {
        var length = high - low

        if length >= 0 {
            return length
        }

        length += 2 * .pi

        if length > 0 {
            return length
        }

        return -1
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

    // Reports whether the interval is empty.
    func isEmpty() -> Bool {
        return low == .pi && high == -.pi
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

    // Returns true iff the interval contains the point.
    // Assumes p ∈ [-π,π].
    func contains(point: Double) -> Bool {
        if point == -.pi {
            return fastContains(point: .pi)
        }

        return fastContains(point: point)
    }

    // Returns true iff the interval contains the other intervel.
    func contains(interval other: S1Interval) -> Bool {
        if isInverted() {
            if other.isInverted() {
                return other.low >= low && other.high <= high
            }

            return (other.low >= low || other.high < high) && !isEmpty()
        } else if other.isInverted() {
            return isFull() || isEmpty()
        }

        return other.low >= low && other.high <= high
    }

    // Returns true iff the interior of the interval contains p.
    // Assumes p ∈ [-π,π].
    func interiorContains(point: Double) -> Bool {
        var pp = point

        if point == -.pi {
            pp = .pi
        }

        if isInverted() {
            return pp > low || pp < high
        }

        return (pp > low && pp < high) || isFull()
    }

    // Returns true iff the interior of the interval contains the other interval.
    func interiorContains(interval other: S1Interval) -> Bool {
        if isInverted() {
            if other.isInverted() {
                return (other.low > low && other.high < high) || other.isEmpty()
            }

            return other.low > low || other.high < high
        } else if other.isInverted() {
            return isFull() || other.isEmpty()
        }

        return (other.low > low && other.high < high) || isFull()
    }
}
