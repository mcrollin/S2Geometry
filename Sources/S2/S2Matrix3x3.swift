//
//  S2Matrix3x3.swift
//  S2Geometry
//
//  Created by Marc Rollin on 4/18/17.
//  Copyright © 2017 Marc Rollin. All rights reserved.
//

import Foundation

/// Represents a traditional 3x3 matrix of floating point values.
/// This is not a full fledged matrix.
/// It only contains the pieces needed to satisfy the computations done within S2.
struct S2Matrix3x3 {
    fileprivate static let rowsCount = 3
    fileprivate static let columnsCount = 3
    fileprivate static let elementsCount = S2Matrix3x3.rowsCount * S2Matrix3x3.columnsCount
    fileprivate var elements: [Double]

    init(_ elements: [Double] = [Double](repeating: 0, count: S2Matrix3x3.elementsCount)) {
        assert(elements.count == S2Matrix3x3.elementsCount, "Should countain \(S2Matrix3x3.elementsCount) elements")

        self.elements = elements
    }
}

// MARK: CustomStringConvertible compliance
extension S2Matrix3x3: CustomStringConvertible {

    var description: String {
        return "[\(self[0, 0].debugDescription), \(self[0, 1].debugDescription), \(self[0, 2].debugDescription)]"
            + " [\(self[1, 0].debugDescription), \(self[1, 1].debugDescription), \(self[1, 2].debugDescription)]"
            + " [\(self[2, 0].debugDescription), \(self[2, 1].debugDescription), \(self[2, 2].debugDescription)]"
    }
}

// MARK: Equatable compliance
extension S2Matrix3x3: Equatable {

    /// - returns: True iff both matrices have similar elements.
    static func == (lhs: S2Matrix3x3, rhs: S2Matrix3x3) -> Bool {
        return lhs.elements == rhs.elements
    }
}

// MARK: Arithmetic operators
extension S2Matrix3x3 {

    /// Multiplies the matrix by the given scale.
    static func * (lhs: S2Matrix3x3, rhs: Double) -> S2Matrix3x3 {
        return S2Matrix3x3(lhs.elements.map { $0 * rhs })
    }

    static func * (lhs: Double, rhs: S2Matrix3x3) -> S2Matrix3x3 {
        return rhs * lhs
    }

    /// Converts the resulting 1x3 matrix into a S2Point.
    ///
    /// - returns: The multiplication of the matrix by a point.
    static func * (lhs: S2Matrix3x3, rhs: XYZPositionable) -> S2Point {
        let xx = lhs[0, 0] * rhs.x + lhs[0, 1] * rhs.y + lhs[0, 2] * rhs.z
        let yy = lhs[1, 0] * rhs.x + lhs[1, 1] * rhs.y + lhs[1, 2] * rhs.z
        let zz = lhs[2, 0] * rhs.x + lhs[2, 1] * rhs.y + lhs[2, 2] * rhs.z

        return S2Point(x: xx, y: yy, z: zz)
    }

    static func * (lhs: XYZPositionable, rhs: S2Matrix3x3) -> S2Point {
        return rhs * lhs
    }
}

// MARK: Private instance methods
fileprivate extension S2Matrix3x3 {

    func index(_ row: Int, _ column: Int) -> Int {
        return row * S2Matrix3x3.rowsCount + column
    }
}

// MARK: Instance methods and computed properties
extension S2Matrix3x3 {

    subscript(row: Int, column: Int) -> Double {
        get {
            return elements[index(row, column)]
        } set(newValue) {
            elements[index(row, column)] = newValue
        }
    }

    /// Determinant of this matrix.
    var determinant: Double {
        //      | a  b  c |
        //  det | d  e  f | = aei + bfg + cdh - ceg - bdi - afh
        //      | g  h  i |
        return self[0, 0] * self[1, 1] * self[2, 2]
            + self[0, 1] * self[1, 2] * self[2, 0]
            + self[0, 2] * self[1, 0] * self[2, 1]
            - self[0, 2] * self[1, 1] * self[2, 0]
            - self[0, 1] * self[1, 0] * self[2, 2]
            - self[0, 0] * self[1, 2] * self[2, 1]
    }

    /// Reflected matrix along its diagonal.
    var transposed: S2Matrix3x3 {
        var copy = self

        swap(&copy[0, 1], &copy[1, 0])
        swap(&copy[0, 2], &copy[2, 0])
        swap(&copy[1, 2], &copy[2, 1])

        return copy
    }

    /// - returns: The given column as a S2Point.
    func column(_ column: Int) -> S2Point {
        return S2Point(x: self[0, column], y: self[1, column], z: self[2, column])
    }

    /// - returns: The given column as a S2Point.
    func row(_ row: Int) -> S2Point {
        return S2Point(x: self[row, 0], y: self[row, 1], z: self[row, 2])
    }

    /// Sets the specified column to the value in the given S2Point.
    ///
    /// - returns: The updated matrix.
    func set(column: Int, to point: S2Point) -> S2Matrix3x3 {
        var copy = self

        copy[0, column] = point.x
        copy[1, column] = point.y
        copy[2, column] = point.z

        return copy
    }

    /// Sets the specified row to the value in the given S2Point.
    ///
    /// - returns: The updated matrix.
    func set(row: Int, to point: S2Point) -> S2Matrix3x3 {
        var copy = self

        copy[row, 0] = point.x
        copy[row, 1] = point.y
        copy[row, 2] = point.z

        return copy
    }
}
