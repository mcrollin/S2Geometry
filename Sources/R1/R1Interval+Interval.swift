//
//  R1Interval+Interval.swift
//  S2Geometry
//
//  Created by Marc Rollin on 4/17/17.
//  Copyright © 2017 Marc Rollin. All rights reserved.
//

import Foundation

// MARK: Interval compliance
extension R1Interval: Interval {

    /// Midpoint of the interval.
    var center: Double {
        return 0.5 * (low + high)
    }

    /// Length of the interval.
    /// The length of an empty interval is negative.
    var length: Double {
        return high - low
    }

    /// Whether the interval is empty.
    var isEmpty: Bool {
        return low > high
    }

    /// Interval representing a single point.
    init(point: Double) {
        low = point
        high = point
    }

    /// - returns: true iff the interval contains the point.
    func contains(point: Double) -> Bool {
        return low <= point && point <= high
    }

    /// - returns: true iff the interval contains the other interval.
    func contains(interval other: R1Interval) -> Bool {
        return other.isEmpty ? true : low <= other.low && other.high <= high
    }

    /// - returns: true iff the interval strictly contains the point.
    func interiorContains(point: Double) -> Bool {
        return low < point && point < high
    }

    /// - returns: true iff the interval strictly contains the other interval.
    func interiorContains(interval other: R1Interval) -> Bool {
        return other.isEmpty ? true : low < other.low && other.high < high
    }

    /// - returns: true iff the interval contains any points in common with the other interval.
    func intersects(with other: R1Interval) -> Bool {
        if low <= other.low {
            // interval.low ∈ self and interval is not empty
            return other.low <= high && other.low <= other.high
        }

        // low ∈ interval and self is not empty
        return low <= other.high && low <= high
    }

    /// Including the the other interval's boundary.
    ///
    /// - returns: true iff the interval's interior contains any points in common.
    func interiorIntersects(with other: R1Interval) -> Bool {
        return other.low < high
            && low < other.high
            && low < high
            && other.low <= other.high
    }

    /// - returns: the interval expanded so that it contains the given point.
    func add(point: Double) -> R1Interval {
        if isEmpty {
            return R1Interval(low: point, high: point)
        } else if point < low {
            return R1Interval(low: point, high: high)
        } else if point > high {
            return R1Interval(low: low, high: point)
        }

        return self
    }

    /// If margin is negative, then the function shrinks the interval on
    /// each side by margin instead. The resulting interval may be empty. Any
    /// expansion of an empty interval remains empty.
    ///
    /// - returns: an interval that has been expanded on each side by margin.
    func expanded(by margin: Double) -> R1Interval {
        if isEmpty {
            return self
        }

        return R1Interval(low: low - margin, high: high + margin)
    }

    /// - returns: the interval containing all points common with the given interval.
    func intersection(with other: R1Interval) -> R1Interval {
        return R1Interval(low: max(low, other.low),
                          high: min(high, other.high))
    }

    /// - returns: the smallest interval that contains this interval and the given interval.
    func union(with other: R1Interval) -> R1Interval {
        if isEmpty {
            return other
        } else if other.isEmpty {
            return self
        }

        return R1Interval(low: min(low, other.low),
                          high: max(high, other.high))
    }
}
