//
//  Interval.swift
//  S2Geometry
//
//  Created by Marc Rollin on 4/16/17.
//  Copyright © 2017 Marc Rollin. All rights reserved.
//

import Foundation

protocol Interval: CustomStringConvertible, Equatable, AlmostEquatable {
    var low: Double { get }
    var high: Double { get }
    var length: Double { get }
    var center: Double { get }

    init(point: Double)

    func isEmpty() -> Bool

    func contains(point: Double) -> Bool
    func contains(interval other: Self) -> Bool
    func interiorContains(point: Double) -> Bool
    func interiorContains(interval other: Self) -> Bool
    func intersects(with other: Self) -> Bool
    func interiorIntersects(with other: Self) -> Bool

    func add(point: Double) -> Self
    func expanded(by margin: Double) -> Self
    func intersection(with other: Self) -> Self
    func union(with other: Self) -> Self
}

extension CustomStringConvertible where Self: Interval {

    var description: String {
        return "[\(low),\(high)]"
    }
}

extension Equatable where Self: Interval {

    // Returns true iff the interval lhs contains the same points as rhs.
    static func == (lhs: Self, rhs: Self) -> Bool {
        return (lhs.low == rhs.low && lhs.high == rhs.high)
            || (lhs.isEmpty() && rhs.isEmpty())
    }
}

extension AlmostEquatable where Self: Interval {

    // Reports whether the interval can be transformed into the
    // given interval by moving each endpoint a small distance.
    // The empty interval is considered to be positioned arbitrarily on the
    // real line, so any interval with a small enough length will match
    // the empty interval.
    static func ==~ (lhs: Self, rhs: Self) -> Bool {
        if lhs.isEmpty() {
            return rhs.length <= 2 * Double.epsilon
        } else if rhs.isEmpty() {
            return lhs.length <= 2 * Double.epsilon
        }

        return lhs.low ==~ rhs.low && lhs.high ==~ rhs.high
    }
}
