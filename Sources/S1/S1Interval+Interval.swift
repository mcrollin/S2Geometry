//
//  S1Interval+Interval.swift
//  S2Geometry
//
//  Created by Marc Rollin on 4/17/17.
//  Copyright © 2017 Marc Rollin. All rights reserved.
//

import Foundation

// MARK: Interval compliance
extension S1Interval: Interval {

    /// Midpoint of the interval.
    /// It is undefined for full and empty intervals.
    var center: Double {
        let center = 0.5 * (low + high)

        if !isInverted {
            return center
        } else if center <= 0 {
            return center + .pi
        }

        return center - .pi
    }

    /// Length of the interval.
    /// The length of an empty interval is negative.
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

    /// Whether the interval is empty.
    var isEmpty: Bool {
        return low == .pi && high == -.pi
    }

    /// Interval representing a single point.
    init(point: Double) {
        self.init(low: point, high: point)
    }

    /// Assumes p ∈ [-π,π].
    ///
    /// - returns: true iff the interval contains the point.
    func contains(point: Double) -> Bool {
        if point == -.pi {
            return fastContains(point: .pi)
        }

        return fastContains(point: point)
    }

    /// - returns: true iff the interval contains the other interval.
    func contains(interval other: S1Interval) -> Bool {
        if isInverted {
            if other.isInverted {
                return other.low >= low && other.high <= high
            }

            return (other.low >= low || other.high < high) && !isEmpty
        } else if other.isInverted {
            return isFull || other.isEmpty
        }

        return other.low >= low && other.high <= high
    }

    /// Assumes p ∈ [-π,π].
    ///
    /// - returns: true iff the interior of the interval contains p.
    func interiorContains(point: Double) -> Bool {
        var pp = point

        if point == -.pi {
            pp = .pi
        }

        if isInverted {
            return pp > low || pp < high
        }

        return (pp > low && pp < high) || isFull
    }

    /// - returns: true iff the interior of the interval contains the other interval.
    func interiorContains(interval other: S1Interval) -> Bool {
        if isInverted {
            if other.isInverted {
                return (other.low > low && other.high < high) || other.isEmpty
            }

            return other.low > low || other.high < high
        } else if other.isInverted {
            return isFull || other.isEmpty
        }

        return (other.low > low && other.high < high) || isFull
    }

    /// - returns: true iff the interval contains any points in common with the other interval.
    func intersects(with other: S1Interval) -> Bool {
        if isEmpty || other.isEmpty {
            return false
        } else if isInverted {
            return other.isInverted
                || other.low <= high
                || other.high >= low
        } else if other.isInverted {
            return other.low <= high
                || other.high >= low
        }

        return other.low <= high && other.high >= low
    }

    /// Including the latter's boundary.
    ///
    /// - returns: true iff the interior of the interval contains any points in common with other.
    func interiorIntersects(with other: S1Interval) -> Bool {
        if isEmpty || other.isEmpty || low == high {
            return false
        } else if isInverted {
            return other.isInverted
                || other.low < high
                || other.high > low
        } else if other.isInverted {
            return other.low < high
                || other.high > low
        }

        return (other.low < high && other.high > low) || isFull
    }

    /// - returns: the smallest interval that contains both intervals.
    func union(with other: S1Interval) -> S1Interval {
        guard !other.isEmpty else {
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
        if isEmpty || other.fastContains(point: low) {
            return other
        }

        // This is the only hard case where we need to find the closest pair of endpoints.
        if S1Interval.positiveDistance(from: other.high, to: low)
            < S1Interval.positiveDistance(from: high, to: other.low) {
            return S1Interval(low: other.low, high: high)
        }

        return S1Interval(low: low, high: other.high)
    }

    /// - returns: the smallest interval that contains the intersection of the interval and other.
    func intersection(with other: S1Interval) -> S1Interval {
        guard !other.isEmpty else {
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

    /// Expandeds the interval by the minimum amount necessary such that it contains the given point.
    ///
    /// - returns: the interval (an angle in the range [-π, π]).
    func add(point: Double) -> S1Interval {
        if abs(point) > .pi {
            return self
        }

        let point = point == -.pi ? .pi : point

        if fastContains(point: point) {
            return self
        } else if isEmpty {
            return S1Interval(point: point)
        } else if S1Interval.positiveDistance(from: point, to: low)
            < S1Interval.positiveDistance(from: high, to: point) {
            return S1Interval(low: point, high: high)
        }

        return S1Interval(low: low, high: point)
    }

    /// If margin is negative, then the function shrinks the interval on
    /// each side by margin instead. The resulting interval may be empty or
    /// full. Any expansion (positive or negative) of a full interval remains
    /// full, and any expansion of an empty interval remains empty.
    ///
    /// - returns: an interval that has been expanded on each side by margin.
    func expanded(by margin: Double) -> S1Interval {
        if margin >= 0 {
            if isEmpty {
                return self
            }

            // Check whether this interval will be full after expansion,
            // allowing for a rounding error when computing each endpoint.
            if length + 2 * margin + 2 * .epsilon >= 2 * .pi {
                return .full
            }
        } else {
            if isFull {
                return self
            }

            // Check whether this interval will be empty after expansion,
            // allowing for a rounding error when computing each endpoint.
            if length + 2 * margin - 2 * .epsilon <= 0 {
                return .empty
            }
        }

        let twoPi = 2.0 * .pi

        let ll = (low - margin).remainder(dividingBy: twoPi)
        let hh = (high + margin).remainder(dividingBy: twoPi)

        return S1Interval(low: ll <= -.pi ? .pi : ll, high: hh)
    }
}
