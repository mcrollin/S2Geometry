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

extension R1Interval {

    // Expands the interval to include the other interval.
    // This is the same as replacing the interval by the union of the two interval.
    static func + (lhs: R1Interval, rhs: R1Interval) -> R1Interval {
        return lhs.union(with: rhs)
    }

    // Empty interval.
    static let empty = R1Interval(low: 1, high: 0)

    // Returns the closest point in the interval to the given point.
    // The interval must be non-empty.
    func clamp(to point: Double) -> Double {
        return max(low, min(high, point))
    }
}
