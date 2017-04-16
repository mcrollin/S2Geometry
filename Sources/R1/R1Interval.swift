//
//  R1Interval.swift
//  S2Geometry
//
//  Created by Marc Rollin on 4/8/17.
//  Copyright © 2017 Marc Rollin. All rights reserved.
//

import Foundation

// R1Interval represents a closed interval on ℝ.
// Zero-length intervals (where low == high) represent single points.
// If low > high then the interval is empty.
struct R1Interval {
    let low: Double
    let high: Double
}

extension R1Interval: Interval {
    // Midpoint of the interval.
    var center: Double {
        return 0.5 * (low + high)
    }

    // Length of the interval.
    // The length of an empty interval is negative.
    var length: Double {
        return high - low
    }

    // Interval representing a single point.
    init(point: Double) {
        low = point
        high = point
    }

    // Reports whether the interval is empty.
    func isEmpty() -> Bool {
        return low > high
    }

    // Returns true iff the interval contains the point.
    func contains(point: Double) -> Bool {
        return low <= point && point <= high
    }

    // Returns true iff the interval contains the other interval.
    func contains(interval other: R1Interval) -> Bool {
        return other.isEmpty() ? true : low <= other.low && other.high <= high
    }

    // Returns true iff the interval strictly contains the point.
    func interiorContains(point: Double) -> Bool {
        return low < point && point < high
    }

    // Returns true iff the interval strictly contains the other interval.
    func interiorContains(interval other: R1Interval) -> Bool {
        return other.isEmpty() ? true : low < other.low && other.high < high
    }

    // Returns true iff the interval contains any points in common with the other interval.
    func intersects(with other: R1Interval) -> Bool {
        if low <= other.low {
            // interval.low ∈ self and interval is not empty
            return other.low <= high && other.low <= other.high
        }

        // low ∈ interval and self is not empty
        return low <= other.high && low <= high
    }

    // Returns true iff the interval's interior contains any points in common,
    // including the the other interval's boundary.
    func interiorIntersects(with other: R1Interval) -> Bool {
        return other.low < high
            && low < other.high
            && low < high
            && other.low <= other.high
    }

    // Returns the interval expanded so that it contains the given point.
    func add(point: Double) -> R1Interval {
        if isEmpty() {
            return R1Interval(low: point, high: point)
        } else if point < low {
            return R1Interval(low: point, high: high)
        } else if point > high {
            return R1Interval(low: low, high: point)
        }

        return self
    }

    // Returns an interval that has been expanded on each side by margin.
    // If margin is negative, then the function shrinks the interval on
    // each side by margin instead. The resulting interval may be empty. Any
    // expansion of an empty interval remains empty.
    func expanded(by margin: Double) -> R1Interval {
        if isEmpty() {
            return self
        }

        return R1Interval(low: low - margin, high: high + margin)
    }

    // Returns the interval containing all points common with the given interval.
    func intersection(with other: R1Interval) -> R1Interval {
        return R1Interval(low: max(low, other.low),
                          high: min(high, other.high))
    }

    // Returns the smallest interval that contains this interval and the given interval.
    func union(with other: R1Interval) -> R1Interval {
        if isEmpty() {
            return other
        } else if other.isEmpty() {
            return self
        }

        return R1Interval(low: min(low, other.low),
                          high: max(high, other.high))
    }
}

extension R1Interval {

    // Expands the interval to include the other interval.
    // This is the same as replacing the interval by the union of the two interval.
    static func + (lhs: R1Interval, rhs: R1Interval) -> R1Interval {
        return lhs.union(with: rhs)
    }

    // Empty interval.
    static var empty: R1Interval {
        return R1Interval(low: 1, high: 0)
    }

    // Returns the closest point in the interval to the given point.
    // The interval must be non-empty.
    func clamp(to point: Double) -> Double {
        return max(low, min(high, point))
    }
}
