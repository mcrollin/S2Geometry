//
//  S2Projection+IJ.swift
//  S2Geometry
//
//  Created by Marc Rollin on 5/1/17.
//  Copyright © 2017 Marc Rollin. All rights reserved.
//

import Foundation

extension S2Projection {

    private func clamp<T: Comparable>(_ value: T, _ lower: T, _ upper: T) -> T {
        assert(lower < upper)

        return min(max(lower, value), upper)
    }

    /// Convert an ij coordinate to the coordinates of a leaf cell just beyond the boundary its face.
    /// This prevents 32-bit overflow in the case of finding the neighbors of a face cell.
    func wrapIJ(ij: Int) -> Int {
        let maxSize = S2CellIdentifier.maxSize

        return clamp(ij, -1, maxSize)
    }

    /// Converts a st value to the corresponding value in ij coordinates.
    func ij(st: Double) -> Int {
        let maxSize = S2CellIdentifier.maxSize

        return clamp(Int(floor(Double(maxSize) * st)), 0, maxSize - 1)
    }

    /// Converts the i- or j-index of a leaf cell to the minimum corresponding s- or t-value contained by that cell.
    /// The argument must be in the range [0 .. 2^30],
    /// i.e. up to one position beyond the normal range of valid leaf cell indices.
    func stMinimum(ij: Int) -> Double {
        let maxSize = S2CellIdentifier.maxSize

        return Double(ij) / Double(maxSize)
    }
}
