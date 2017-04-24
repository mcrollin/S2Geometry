//
//  XYZPositionable.swift
//  S2Geometry
//
//  Created by Marc Rollin on 4/29/17.
//  Copyright © 2017 Marc Rollin. All rights reserved.
//

import Foundation

protocol XYZPositionable {
    var x: Double { get }
    var y: Double { get }
    var z: Double { get }
}

// MARK: Equatable default implementation
extension Equatable where Self: XYZPositionable {

    /// - returns: true iff both XYZPositionable have similar x, y and z.
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.x == rhs.x
            && lhs.y == rhs.y
            && lhs.z == rhs.z
    }
}

// MARK: Comparable default implementation
// Two entities are compared element by element with the given operator.
// The first mismatch defines which is less (or greater) than the other.
// If both have equivalent values they are lexicographically equal.
extension Comparable where Self: XYZPositionable & Equatable {

    static func < (lhs: Self, rhs: Self) -> Bool {
        if lhs.x != rhs.x {
            return lhs.x < rhs.x
        } else if lhs.y != rhs.y {
            return lhs.y < rhs.y
        }

        return lhs.z < rhs.z
    }
}
