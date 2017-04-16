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

extension S1Interval: Interval {

    // Midpoint of the interval.
    // It is undefined for full and empty intervals.
    var center: Double {
        let center = 0.5 * (low + high)

        if !isInverted() {
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

    // Interval representing a single point.
    init(point: Double) {
        self.init(low: point, high: point)
    }

    // Reports whether the interval is empty.
    func isEmpty() -> Bool {
        return low == .pi && high == -.pi
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
            return isFull() || other.isEmpty()
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

    // Returns true iff the interval contains any points in common with the other interval.
    func intersects(with other: S1Interval) -> Bool {
        if isEmpty() || other.isEmpty() {
            return false
        } else if isInverted() {
            return other.isInverted()
                || other.low <= high
                || other.high >= low
        } else if other.isInverted() {
            return other.low <= high
                || other.high >= low
        }

        return other.low <= high && other.high >= low
    }

    // Returns true iff the interior of the interval contains any points in common with other,
    // including the latter's boundary.
    func interiorIntersects(with other: S1Interval) -> Bool {
        if isEmpty() || other.isEmpty() || low == high {
            return false
        } else if isInverted() {
            return other.isInverted()
                || other.low < high
                || other.high > low
        } else if other.isInverted() {
            return other.low < high
                || other.high > low
        }

        return (other.low < high && other.high > low) || isFull()
    }

    // Returns the smallest interval that contains both intervals.
    func union(with other: S1Interval) -> S1Interval {
        guard !other.isEmpty() else {
            return self
        }

        if fastContains(point: other.low) {
            if fastContains(point: other.high) {
                // Either oi ⊂ i, or i ∪ oi is the full interval.
                if contains(interval: other) {
                    return self
                }

                return .full
            }

            return S1Interval(low: low, high: other.high)
        } else if fastContains(point: other.high) {
            return S1Interval(low: other.low, high: high)
        }

        // Neither endpoint of other is in self.
        // Either self ⊂ other, or self and other are disjoint.
        if isEmpty() || other.fastContains(point: low) {
            return other
        }

        // This is the only hard case where we need to find the closest pair of endpoints.
        if S1Interval.positiveDistance(from: other.high, to: low)
            < S1Interval.positiveDistance(from: high, to: other.low) {
            return S1Interval(low: other.low, high: high)
        }

        return S1Interval(low: low, high: other.high)
    }

    // Returns the smallest interval that contains the intersection of the interval and other.
    func intersection(with other: S1Interval) -> S1Interval {
        guard !other.isEmpty() else {
            return .empty
        }

        if fastContains(point: other.low) {
            if fastContains(point: other.high) {
                // Either other ⊂ self, or self and other intersect twice. Neither are empty.
                // In the first case we want to return self (which is shorter than other).
                // In the second case one of them is inverted, and the smallest interval
                // that covers the two disjoint pieces is the shorter of self and other.
                // We thus want to pick the shorter of self and other in both cases.
                if other.length < length {
                    return other
                }

                return self
            }

            return S1Interval(low: other.low, high: high)
        } else if fastContains(point: other.high) {
            return S1Interval(low: low, high: other.high)
        }

        // Neither endpoint of other is in self.
        // Either self ⊂ other, or self and other are disjoint.
        if other.fastContains(point: low) {
            return self
        }

        return .empty
    }

    // Returns the interval expanded by the minimum amount necessary such
    // that it contains the given point (an angle in the range [-π, π]).
    func add(point: Double) -> S1Interval {
        if abs(point) > .pi {
            return self
        }

        let point = point == -.pi ? .pi : point

        if fastContains(point: point) {
            return self
        } else if isEmpty() {
            return S1Interval(point: point)
        } else if S1Interval.positiveDistance(from: point, to: low)
            < S1Interval.positiveDistance(from: high, to: point) {
            return S1Interval(low: point, high: high)
        }

        return S1Interval(low: low, high: point)
    }

    // Returns an interval that has been expanded on each side by margin.
    // If margin is negative, then the function shrinks the interval on
    // each side by margin instead. The resulting interval may be empty or
    // full. Any expansion (positive or negative) of a full interval remains
    // full, and any expansion of an empty interval remains empty.
    func expanded(by margin: Double) -> S1Interval {
        if margin >= 0 {
            if isEmpty() {
                return self
            }

            // Check whether this interval will be full after expansion,
            // allowing for a rounding error when computing each endpoint.
            if length + 2 * margin + 2 * Double.epsilon >= 2 * .pi {
                return .full
            }
        } else {
            if isFull() {
                return self
            }

            // Check whether this interval will be empty after expansion,
            // allowing for a rounding error when computing each endpoint.
            if length + 2 * margin - 2 * Double.epsilon <= 0 {
                return .empty
            }
        }

        let twoPi = 2.0 * .pi

        let ll = (low - margin).remainder(dividingBy: twoPi)
        let hh = (high + margin).remainder(dividingBy: twoPi)

        return S1Interval(low: ll <= -.pi ? .pi : ll, high: hh)
    }
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

    init(unboundedLow: Double, unboundedHigh: Double) {
        low = unboundedLow
        high = unboundedHigh
    }
}

extension S1Interval {

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
        return S1Interval(low: high, high: low)
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
}
