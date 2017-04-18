//
//  R1Interval.swift
//  S2Geometry
//
//  Created by Marc Rollin on 4/8/17.
//  Copyright © 2017 Marc Rollin. All rights reserved.
//

import Foundation

/// R1Interval represents a closed interval on ℝ.
/// Zero-length intervals (where low == high) represent single points.
/// If low > high then the interval is empty.
struct R1Interval {
    let low: Double
    let high: Double
}

// MARK: Static factories and Arithmetic operators
extension R1Interval {

    /// Empty interval.
    static let empty = R1Interval(low: 1, high: 0)

    /// Expands the interval to include the other interval.
    /// This is the same as replacing the interval by the union of the two interval.
    ///
    /// - returns: the expanded interval.
    static func + (lhs: R1Interval, rhs: R1Interval) -> R1Interval {
        return lhs.union(with: rhs)
    }
}

// MARK: Instance methods and computed properties
extension R1Interval {

    /// The interval must be non-empty.
    ///
    /// - returns: the closest point in the interval to the given point.
    func clamp(to point: Double) -> Double {
        return max(low, min(high, point))
    }
}
