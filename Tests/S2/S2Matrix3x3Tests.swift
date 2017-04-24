//
//  S2Matrix3x3Tests.swift
//  S2Geometry
//
//  Created by Marc Rollin on 4/18/17.
//  Copyright © 2017 Marc Rollin. All rights reserved.
//

@testable import S2Geometry
import XCTest

class S2Matrix3x3Tests: XCTestCase {

    func testStringConversion() {
        typealias Test = (matrix: S2Matrix3x3, expected: String)

        let tests = [Test(matrix: S2Matrix3x3([1, 2, 3, 4, 5, 6, 7, 8, 9]),
                          expected: "[1.0, 2.0, 3.0] [4.0, 5.0, 6.0] [7.0, 8.0, 9.0]")]

        for test in tests {
            let got = test.matrix.description

            XCTAssertEqual(got, test.expected, "with \(test.matrix)")
        }
    }

    func testColumn() {
        typealias Test = (matrix: S2Matrix3x3, column: Int, expected: S2Point)

        let matrix = S2Matrix3x3([1, 2, 3, 4, 5, 6, 7, 8, 9])
        let tests = [
            Test(matrix: S2Matrix3x3(), column: 0, expected: S2Point.coordinates(x: 0, y: 0, z: 0)),
            Test(matrix: matrix, column: 0, expected: S2Point(x: 1, y: 4, z: 7)),
            Test(matrix: matrix, column: 2, expected: S2Point(x: 3, y: 6, z: 9))
        ]

        for test in tests {
            XCTAssert(test.matrix.column(test.column) ==~ test.expected, "with \(test.matrix) and \(test.column)")
        }
    }

    func testRow() {
        typealias Test = (matrix: S2Matrix3x3, row: Int, expected: S2Point)

        let matrix = S2Matrix3x3([1, 2, 3, 4, 5, 6, 7, 8, 9])
        let tests = [
            Test(matrix: S2Matrix3x3(), row: 0, expected: .origin),
            Test(matrix: matrix, row: 0, expected: S2Point(x: 1, y: 2, z: 3)),
            Test(matrix: matrix, row: 2, expected: S2Point(x: 7, y: 8, z: 9))
        ]

        for test in tests {
            XCTAssert(test.matrix.row(test.row) ==~ test.expected, "with \(test.matrix) and \(test.row)")
        }
    }

    func testSetColumn() {
        typealias Test = (matrix: S2Matrix3x3, column: Int, point: S2Point, expected: S2Matrix3x3)

        let tests = [
            Test(matrix: S2Matrix3x3(), column: 0, point: S2Point(x: 1, y: 1, z: 0),
                 expected: S2Matrix3x3([1, 0, 0, 1, 0, 0, 0, 0, 0])),
            Test(matrix: S2Matrix3x3([1, 2, 3, 4, 5, 6, 7, 8, 9]),
                 column: 2, point: S2Point(x: 1, y: 1, z: 0),
                 expected: S2Matrix3x3([1, 2, 1, 4, 5, 1, 7, 8, 0]))
        ]

        for test in tests {
            let got = test.matrix.set(column: test.column, to: test.point)

            XCTAssertEqual(got, test.expected, "with \(test.matrix), \(test.column) and \(test.point)")
        }
    }

    func testSetRow() {
        typealias Test = (matrix: S2Matrix3x3, row: Int, point: S2Point, expected: S2Matrix3x3)

        let tests = [
            Test(matrix: S2Matrix3x3(), row: 0, point: S2Point(x: 1, y: 1, z: 0),
                 expected: S2Matrix3x3([1, 1, 0, 0, 0, 0, 0, 0, 0])),
            Test(matrix: S2Matrix3x3([1, 2, 3, 4, 5, 6, 7, 8, 9]),
                 row: 2, point: S2Point(x: 1, y: 1, z: 0),
                 expected: S2Matrix3x3([1, 2, 3, 4, 5, 6, 1, 1, 0]))
        ]

        for test in tests {
            let got = test.matrix.set(row: test.row, to: test.point)

            XCTAssertEqual(got, test.expected, "with \(test.matrix), \(test.row) and \(test.point)")
        }
    }

    func testScale() {
        typealias Test = (matrix: S2Matrix3x3, scale: Double, expected: S2Matrix3x3)

        let matrix = S2Matrix3x3([Double](repeating: 1, count: 9))
        let tests = [
            Test(matrix: S2Matrix3x3(), scale: 0, expected: S2Matrix3x3()),
            Test(matrix: matrix, scale: 0,
                 expected: S2Matrix3x3([Double](repeating: 0, count: 9))),
            Test(matrix: matrix, scale: 1, expected: matrix),
            Test(matrix: matrix, scale: 5,
                 expected: S2Matrix3x3([Double](repeating: 5, count: 9))),
            Test(matrix: S2Matrix3x3([ -2, 2, -3, -1, 1, 3, 2, 0, -1]), scale: 2.75,
                 expected: S2Matrix3x3([ -5.5, 5.5, -8.25, -2.75, 2.75, 8.25, 5.5, 0, -2.75]))
        ]

        for test in tests {
            let got = test.matrix * test.scale
            let got2 = test.scale * test.matrix

            XCTAssertEqual(got, test.expected, "with \(test.matrix), \(test.scale)")
            XCTAssertEqual(got2, test.expected, "with \(test.matrix), \(test.scale)")
        }
    }

    func testMultiply() {
        typealias Test = (matrix: S2Matrix3x3, point: S2Point, expected: S2Point)

        let tests = [
            Test(matrix: S2Matrix3x3([Double](repeating: 1, count: 9)),
                 point: S2Point(x: 0, y: 0, z: 0),
                 expected: S2Point(x: 0, y: 0, z: 0)),
            Test(matrix: S2Matrix3x3([1, 0, 0, 0, 1, 0, 0, 0, 1]),
                 point: S2Point(x: 0, y: 0, z: 0),
                 expected: S2Point(x: 0, y: 0, z: 0)),
            Test(matrix: S2Matrix3x3([1, 0, 0, 0, 1, 0, 0, 0, 1]),
                 point: S2Point(x: 1, y: 2, z: 3),
                 expected: S2Point(x: 1, y: 2, z: 3)),
            Test(matrix: S2Matrix3x3([1, 2, 3, 4, 5, 6, 7, 8, 9]),
                 point: S2Point(x: 1, y: 1, z: 1),
                 expected: S2Point(x: 6, y: 15, z: 24))
        ]

        for test in tests {
            let got = test.matrix * test.point
            let got2 = test.point * test.matrix

            XCTAssertEqual(got, test.expected, "with \(test.matrix), \(test.point)")
            XCTAssertEqual(got2, test.expected, "with \(test.matrix), \(test.point)")
        }
    }

    func testDeterminant() {
        typealias Test = (matrix: S2Matrix3x3, expected: Double)

        let tests = [
            Test(matrix: S2Matrix3x3(), expected: 0),
            Test(matrix: S2Matrix3x3([Double](repeating: 1, count: 9)), expected: 0),
            Test(matrix: S2Matrix3x3([1, 0, 0, 0, 1, 0, 0, 0, 1]), expected: 1),
            Test(matrix: S2Matrix3x3([ -2, 2, -3, -1, 1, 3, 2, 0, -1]), expected: 18),
            Test(matrix: S2Matrix3x3([1, 2, 3, 4, 5, 6, 7, 8, 9]), expected: 0),
            Test(matrix: S2Matrix3x3([9, 8, 7, 6, 5, 4, 3, 2, 1]), expected: 0)
        ]

        for test in tests {
            XCTAssertEqual(test.matrix.determinant, test.expected, "with \(test.matrix)")
        }
    }

    func testTransposed() {
        typealias Test = (matrix: S2Matrix3x3, expected: S2Matrix3x3)

        let tests = [
            Test(matrix: S2Matrix3x3(), expected: S2Matrix3x3()),
            Test(matrix: S2Matrix3x3([1, 2, 3, 4, 5, 6, 7, 8, 9]),
                 expected: S2Matrix3x3([1, 4, 7, 2, 5, 8, 3, 6, 9])),
            Test(matrix: S2Matrix3x3([1, 0, 0, 0, 2, 0, 0, 0, 3]),
                 expected: S2Matrix3x3([1, 0, 0, 0, 2, 0, 0, 0, 3])),
            Test(matrix: S2Matrix3x3([1, 2, 3, 0, 4, 5, 0, 0, 6]),
                 expected: S2Matrix3x3([1, 0, 0, 2, 4, 0, 3, 5, 6])),
            Test(matrix: S2Matrix3x3([1, 1, 1, 0, 0, 0, 0, 0, 0]),
                 expected: S2Matrix3x3([1, 0, 0, 1, 0, 0, 1, 0, 0]))
        ]

        for test in tests {
            XCTAssertEqual(test.matrix.transposed, test.expected, "with \(test.matrix)")
        }
    }

    func testFrame() {
        let point = S2Point.coordinates(x: 0.2, y: 0.5, z: -3.3)
        let frame = point.frame

        XCTAssert(frame.column(0).isUnit)
        XCTAssert(frame.column(1).isUnit)
        XCTAssert(frame.determinant ==~ 1)

        typealias Test = (a: S2Point, b: S2Point)

        let tests = [
            Test(a: frame.column(2), b: point),
            Test(a: S2Point.to(frame: frame, point: frame.column(0)), b: S2Point(x: 1, y: 0, z: 0)),
            Test(a: S2Point.to(frame: frame, point: frame.column(1)), b: S2Point(x: 0, y: 1, z: 0)),
            Test(a: S2Point.to(frame: frame, point: frame.column(2)), b: S2Point(x: 0, y: 0, z: 1)),
            Test(a: S2Point.from(frame: frame, point: S2Point(x: 1, y: 0, z: 0)), b: frame.column(0)),
            Test(a: S2Point.from(frame: frame, point: S2Point(x: 0, y: 1, z: 0)), b: frame.column(1)),
            Test(a: S2Point.from(frame: frame, point: S2Point(x: 0, y: 0, z: 1)), b: frame.column(2))
        ]

        for test in tests {
            XCTAssert(test.a ==~ test.b, "with \(test.a) and \(test.b)")
        }
    }
}
