//
//  AlmostEquatable.swift
//  S2Geometry
//
//  Created by Marc Rollin on 4/9/17.
//  Copyright © 2017 Marc Rollin. All rights reserved.
//

import Foundation

infix operator ==~ : ComparisonPrecedence

protocol AlmostEquatable {
    static func ==~ (lhs: Self, rhs: Self) -> Bool
}

public protocol EquatableWithinEpsilon: Strideable {
    static var epsilon: Self.Stride { get }
}

private func almostEqual<T: EquatableWithinEpsilon>(_ lhs: T, _ rhs: T, epsilon: T.Stride) -> Bool {
    return abs(lhs - rhs) <= epsilon
}

func ==~<T: AlmostEquatable & EquatableWithinEpsilon>(lhs: T, rhs: T) -> Bool {
    return almostEqual(lhs, rhs, epsilon: T.epsilon)
}

extension Double: EquatableWithinEpsilon {

    // epsilon is a small number that represents a reasonable level of noise
    // between two values that can be considered to be equal.
    public static let epsilon: Double.Stride = ulpOfOne // 2.22044604925031e-16
}

extension Double: AlmostEquatable {}
