//
//  R2PointTests.swift
//  S2Geometry
//
//  Created by Marc Rollin on 4/9/17.
//  Copyright © 2017 Marc Rollin. All rights reserved.
//

import XCTest
@testable import S2Geometry

// swiftlint:disable nesting
// swiftlint:disable line_length

class R2PointTests: XCTestCase {

    func testStringConversion() {
        struct Test {
            let interval: R2Point
            let expected: String
        }

        let tests = [Test(interval: R2Point(x: 2, y: 4.5), expected: "(2.0,4.5)")]

        for test in tests {
            let got = test.interval.description

            XCTAssertEqual(got, test.expected, "with \(test.interval)")
        }
    }

    func testAdd() {
        struct Test {
            let point: R2Point
            let other: R2Point
            let expected: R2Point
        }

        let tests = [Test(point: R2Point(x: 2, y: -1), other: R2Point(x: -2, y: 1), expected: R2Point(x: 0, y: 0))]

        for test in tests {
            let got = test.point + test.other

            XCTAssertEqual(got, test.expected, "with \(test.point) and \(test.other)")
        }
    }

    func testSubstract() {
        struct Test {
            let point: R2Point
            let other: R2Point
            let expected: R2Point
        }

        let tests = [Test(point: R2Point(x: 2, y: -1), other: R2Point(x: -2, y: 1), expected: R2Point(x: 4, y: -2))]

        for test in tests {
            let got = test.point - test.other

            XCTAssertEqual(got, test.expected, "with \(test.point) and \(test.other)")
        }
    }

    func testMultiply() {
        struct Test {
            let point: R2Point
            let by: Double
            let expected: R2Point
        }

        let tests = [Test(point: R2Point(x: 2, y: -1), by: 2.0, expected: R2Point(x: 4, y: -2))]

        for test in tests {
            let got = test.point * test.by
            let got2 = test.by * test.point

            XCTAssertEqual(got, test.expected, "with \(test.point) and \(test.by)")
            XCTAssertEqual(got2, test.expected, "with \(test.point) and \(test.by)")
        }
    }

    func testDivide() {
        struct Test {
            let point: R2Point
            let by: Double
            let expected: R2Point
        }

        let tests = [Test(point: R2Point(x: 2, y: -1), by: 2.0, expected: R2Point(x: 1, y: -0.5))]

        for test in tests {
            let got = test.point / test.by

            XCTAssertEqual(got, test.expected, "with \(test.point) and \(test.by)")
        }
    }

    func testNormal() {
        struct Test {
            let point: R2Point
            let expected: Double
        }

        let tests = [Test(point: R2Point(x: 0, y: 0), expected: 0),
                     Test(point: R2Point(x: 0, y: 1), expected: 1),
                     Test(point: R2Point(x: -1, y: 0), expected: 1),
                     Test(point: R2Point(x: 3, y: 4), expected: 5),
                     Test(point: R2Point(x: 3, y: -4), expected: 5),
                     Test(point: R2Point(x: 2, y: 2), expected: 2 * sqrt(2)),
                     Test(point: R2Point(x: 1, y: sqrt(3)), expected: 2),
                     Test(point: R2Point(x: 29, y: 29 * sqrt(3)), expected: 29 * 2),
                     Test(point: R2Point(x: 1, y: 1e15), expected: 1e15)]

        for test in tests {
            let got = test.point.normal

            XCTAssertEqual(got, test.expected, "with \(test.point)")
        }
    }

    func testNormalized() {
        struct Test {
            let point: R2Point
            let expected: R2Point
        }

        let tests = [Test(point: R2Point(x: 0, y: 0), expected: R2Point(x: 0, y: 0)),
                     Test(point: R2Point(x: 0, y: 1), expected: R2Point(x: 0, y: 1)),
                     Test(point: R2Point(x: -1, y: 0), expected: R2Point(x: -1, y: 0)),
                     Test(point: R2Point(x: 3, y: 4), expected: R2Point(x: 0.6, y: 0.8)),
                     Test(point: R2Point(x: 3, y: -4), expected: R2Point(x: 0.6, y: -0.8)),
                     Test(point: R2Point(x: 2, y: 2), expected: R2Point(x: sqrt(2) / 2, y: sqrt(2) / 2)),
                     Test(point: R2Point(x: 7, y: 7 * sqrt(3)), expected: R2Point(x: 0.5, y: sqrt(3) / 2)),
                     Test(point: R2Point(x: 1e21, y: 1e21 * sqrt(3)), expected: R2Point(x: 0.5, y: sqrt(3) / 2)),
                     Test(point: R2Point(x: 1, y: 1e16), expected: R2Point(x: 0, y: 1))]

        for test in tests {
            let got = test.point.normalized

            XCTAssert(got ==~ test.expected, "with \(test.point)")
        }
    }

    func testOrthogonal() {
        struct Test {
            let point: R2Point
            let expected: R2Point
        }

        let tests = [Test(point: R2Point(x: 0, y: 0), expected: R2Point(x: 0, y: 0)),
                     Test(point: R2Point(x: 0, y: 1), expected: R2Point(x: -1, y: 0)),
                     Test(point: R2Point(x: 1, y: 1), expected: R2Point(x: -1, y: 1)),
                     Test(point: R2Point(x: -4, y: 7), expected: R2Point(x: -7, y: -4)),
                     Test(point: R2Point(x: 1, y: sqrt(3)), expected: R2Point(x: -sqrt(3), y: 1))]

        for test in tests {
            let got = test.point.orthogonal

            XCTAssertEqual(got, test.expected, "with \(test.point)")
        }
    }

    func testDotProduct() {
        struct Test {
            let point: R2Point
            let other: R2Point
            let expected: Double
        }

        let tests = [Test(point: R2Point(x: 0, y: 0), other: R2Point(x: 0, y: 0), expected: 0),
                     Test(point: R2Point(x: 0, y: 1), other: R2Point(x: 0, y: 0), expected: 0),
                     Test(point: R2Point(x: 1, y: 1), other: R2Point(x: 4, y: 3), expected: 7),
                     Test(point: R2Point(x: -4, y: 7), other: R2Point(x: 1, y: 5), expected: 31)]

        for test in tests {
            let got = test.point.dotProduct(with: test.other)

            XCTAssertEqual(got, test.expected, "with \(test.point) and \(test.other)")
        }
    }

    func testCrossProduct() {
        struct Test {
            let point: R2Point
            let other: R2Point
            let expected: Double
        }

        let tests = [Test(point: R2Point(x: 0, y: 0), other: R2Point(x: 0, y: 0), expected: 0),
                     Test(point: R2Point(x: 0, y: 1), other: R2Point(x: 0, y: 0), expected: 0),
                     Test(point: R2Point(x: 1, y: 1), other: R2Point(x: -1, y: -1), expected: 0),
                     Test(point: R2Point(x: 1, y: 1), other: R2Point(x: 4, y: 3), expected: -1),
                     Test(point: R2Point(x: 1, y: 5), other: R2Point(x: -2, y: 3), expected: 13)]

        for test in tests {
            let got = test.point.crossProduct(with: test.other)

            XCTAssertEqual(got, test.expected, "with \(test.point) and \(test.other)")
        }
    }
}
