//
//  R1IntervalTests.swift
//  S2Geometry
//
//  Created by Marc Rollin on 4/8/17.
//  Copyright © 2017 Marc Rollin. All rights reserved.
//

import XCTest
@testable import S2Geometry

// swiftlint:disable nesting
// swiftlint:disable line_length
// swiftlint:disable function_body_length
// swiftlint:disable type_body_length

class R1IntervalTests: XCTestCase {

    struct TestIntervals {
        let unit = R1Interval(low: 0, high: 1)
        let negativeUnit = R1Interval(low: -1, high: 0)
        let half = R1Interval(low: 0.5, high: 0.5)
        let empty = R1Interval(low: 1, high: 0)
    }

    let i = TestIntervals()

    func testStringConversion() {
        struct Test {
            let interval: R1Interval
            let expected: String
        }

        let tests = [Test(interval: R1Interval(low: 2, high: 4.5), expected: "[2.0,4.5]")]

        for test in tests {
            let got = test.interval.description

            XCTAssertEqual(got, test.expected, "with \(test.interval)")
        }
    }

    func testAlmostEqual() {
        struct Test {
            let interval: R1Interval
            let other: R1Interval
            let expected: Bool
        }

        let tests = [Test(interval: i.empty, other: i.empty, expected: true),
                     Test(interval: R1Interval(point: 0), other: i.empty, expected: true),
                     Test(interval: i.empty, other: R1Interval(point: 0), expected: true),
                     Test(interval: R1Interval(point: 1), other: i.empty, expected: true),
                     Test(interval: i.empty, other: R1Interval(point: 1), expected: true),
                     Test(interval: i.empty, other: R1Interval(low: 0, high: 1), expected: false),
                     Test(interval: i.empty, other: R1Interval(low: 1, high: 1 + 2 * Double.epsilon), expected: true),

                     Test(interval: R1Interval(point: 1), other: R1Interval(point: 1), expected: true),
                     Test(interval: R1Interval(point: 1), other: R1Interval(low: 1 - Double.epsilon, high: 1 - Double.epsilon), expected: true),
                     Test(interval: R1Interval(point: 1), other: R1Interval(low: 1 + Double.epsilon, high: 1 + Double.epsilon), expected: true),
                     Test(interval: R1Interval(point: 1), other: R1Interval(low: 1 - 3 * Double.epsilon, high: 1), expected: false),
                     Test(interval: R1Interval(point: 1), other: R1Interval(low: 1, high: 1 + 3 * Double.epsilon), expected: false),
                     Test(interval: R1Interval(point: 1), other: R1Interval(low: 1 - Double.epsilon, high: 1 + Double.epsilon), expected: true),
                     Test(interval: R1Interval(point: 0), other: R1Interval(point: 1), expected: false),

                     Test(interval: R1Interval(low: 1 - Double.epsilon, high: 2 + Double.epsilon), other: R1Interval(low: 1, high: 2), expected: true),
                     Test(interval: R1Interval(low: 1 + Double.epsilon, high: 2 - Double.epsilon), other: R1Interval(low: 1, high: 2), expected: true),
                     Test(interval: R1Interval(low: 1 - 3 * Double.epsilon, high: 2 + Double.epsilon), other: R1Interval(low: 1, high: 2), expected: false),
                     Test(interval: R1Interval(low: 1 + 3 * Double.epsilon, high: 2 - Double.epsilon), other: R1Interval(low: 1, high: 2), expected: false),
                     Test(interval: R1Interval(low: 1 - Double.epsilon, high: 2 + 3 * Double.epsilon), other: R1Interval(low: 1, high: 2), expected: false),
                     Test(interval: R1Interval(low: 1 + Double.epsilon, high: 2 - 3 * Double.epsilon), other: R1Interval(low: 1, high: 2), expected: false)]

        for test in tests {
            let got = test.interval ==~ test.other

            XCTAssertEqual(got, test.expected, "with \(test.interval) and \(test.other)")
        }
    }

    func testIsEmpty() {
        XCTAssertFalse(i.unit.isEmpty(), "\(i.unit) should not be empty")
        XCTAssertFalse(i.negativeUnit.isEmpty(), "\(i.negativeUnit) should not be empty")
        XCTAssertFalse(i.half.isEmpty(), "\(i.half) should not be empty")
        XCTAssertTrue(i.empty.isEmpty(), "\(i.empty) should be empty")
    }

    func testCenter() {
        struct Test {
            let interval: R1Interval
            let expects: Double
        }

        let tests = [Test(interval: i.unit, expects: 0.5),
                     Test(interval: i.negativeUnit, expects: -0.5),
                     Test(interval: i.half, expects: 0.5)]

        for test in tests {
            let got = test.interval.center

            XCTAssertEqual(got, test.expects, "with \(test.interval)")
        }
    }

    func testLength() {
        struct Test {
            let interval: R1Interval
            let expects: Double
        }

        let tests = [Test(interval: i.unit, expects: 1),
                     Test(interval: i.negativeUnit, expects: 1),
                     Test(interval: i.half, expects: 0)]

        for test in tests {
            let got = test.interval.length

            XCTAssertEqual(got, test.expects, "with \(test.interval)")
        }
    }

    func testIntervalPointOperations() {
        struct Test {
            let interval: R1Interval
            let point: Double
            let contains: Bool
            let interiorContains: Bool
        }

        let tests = [Test(interval: i.unit, point: 0.5, contains: true, interiorContains: true)]

        for test in tests {
            let contains = test.interval.contains(point: test.point)
            let interiorContains = test.interval.interiorContains(point: test.point)

            XCTAssertEqual(contains, test.contains, "with \(test.interval)")
            XCTAssertEqual(interiorContains, test.interiorContains, "with \(test.interval)")
        }
    }

    func testIntervalsOperations() {
        struct Test {
            let interval: R1Interval
            let other: R1Interval
            let contains: Bool
            let interiorContains: Bool
            let intersects: Bool
            let interiorIntersects: Bool
        }

        let tests = [Test(interval: i.empty, other: i.empty,
                          contains: true, interiorContains: true,
                          intersects: false, interiorIntersects: false),
                     Test(interval: i.empty, other: i.unit,
                          contains: false, interiorContains: false,
                          intersects: false, interiorIntersects: false),
                     Test(interval: i.unit, other: i.half,
                          contains: true, interiorContains: true,
                          intersects: true, interiorIntersects: true),
                     Test(interval: i.unit, other: i.unit,
                          contains: true, interiorContains: false,
                          intersects: true, interiorIntersects: true),
                     Test(interval: i.unit, other: i.empty,
                          contains: true, interiorContains: true,
                          intersects: false, interiorIntersects: false),
                     Test(interval: i.unit, other: i.negativeUnit,
                          contains: false, interiorContains: false,
                          intersects: true, interiorIntersects: false),
                     Test(interval: i.unit, other: R1Interval(low: 0, high: 0.5),
                          contains: true, interiorContains: false,
                          intersects: true, interiorIntersects: true),
                     Test(interval: i.half, other: R1Interval(low: 0, high: 0.5),
                          contains: false, interiorContains: false,
                          intersects: true, interiorIntersects: false),
                     Test(interval: R1Interval(low: 1, high: 2.1),
                          other: R1Interval(low: 2, high: 1.9),
                          contains: true, interiorContains: true,
                          intersects: false, interiorIntersects: false)]

        for test in tests {
            let contains = test.interval.contains(interval: test.other)
            let interiorContains = test.interval.interiorContains(interval: test.other)
            let intersects = test.interval.intersects(with: test.other)
            let interiorIntersects = test.interval.interiorIntersects(with: test.other)

            XCTAssertEqual(contains, test.contains, "with \(test.interval) and \(test.other)")
            XCTAssertEqual(interiorContains, test.interiorContains, "with \(test.interval) and \(test.other)")
            XCTAssertEqual(intersects, test.intersects, "with \(test.interval) and \(test.other)")
            XCTAssertEqual(interiorIntersects, test.interiorIntersects, "with \(test.interval) and \(test.other)")
        }
    }

    func testIntersection() {
        struct Test {
            let x: R1Interval
            let y: R1Interval
            let expected: R1Interval
        }

        let tests = [Test(x: i.unit, y: i.half, expected: i.half),
                     Test(x: i.unit, y: i.negativeUnit, expected: R1Interval(low: 0, high: 0)),
                     Test(x: i.negativeUnit, y: i.half, expected: i.empty),
                     Test(x: i.unit, y: i.empty, expected: i.empty),
                     Test(x: i.empty, y: i.unit, expected: i.empty)]

        for test in tests {
            let got = test.x.intersection(with: test.y)

            XCTAssertEqual(got, test.expected, "with \(test.x) and \(test.y)")
        }
    }

    func testUnion() {
        struct Test {
            let x: R1Interval
            let y: R1Interval
            let expected: R1Interval
        }

        let tests = [Test(x: R1Interval(low: 99, high: 100), y: i.empty, expected: R1Interval(low: 99, high: 100)),
                     Test(x: i.empty, y: R1Interval(low: 99, high: 100), expected: R1Interval(low: 99, high: 100)),
                     Test(x: R1Interval(low: 5, high: 3), y: R1Interval(low: 0, high: -2), expected: i.empty),
                     Test(x: R1Interval(low: 0, high: -2), y: R1Interval(low: 5, high: 3), expected: i.empty),
                     Test(x: i.unit, y: i.unit, expected: i.unit),
                     Test(x: i.unit, y: i.negativeUnit, expected: R1Interval(low: -1, high: 1)),
                     Test(x: i.negativeUnit, y: i.unit, expected: R1Interval(low: -1, high: 1)),
                     Test(x: i.half, y: i.unit, expected: i.unit)]

        for test in tests {
            let got = test.x.union(with: test.y)

            XCTAssertEqual(got, test.expected, "with \(test.x) and \(test.y)")
        }

        for test in tests {
            let got = test.x + test.y

            XCTAssertEqual(got, test.expected, "with \(test.x) and \(test.y)")
        }
    }

    func testAddPoint() {
        struct Test {
            let interval: R1Interval
            let point: Double
            let expected: R1Interval
        }

        let tests = [Test(interval: .empty, point: 5, expected: R1Interval(low: 5, high: 5)),
                     Test(interval: R1Interval(point: 5), point: -1, expected: R1Interval(low: -1, high: 5)),
                     Test(interval: R1Interval(low: -1, high: 5), point: 0, expected: R1Interval(low: -1, high: 5)),
                     Test(interval: R1Interval(low: -1, high: 5), point: 6, expected: R1Interval(low: -1, high: 6))]

        for test in tests {
            let got = test.interval.add(point: test.point)

            XCTAssertEqual(got, test.expected, "with \(test.interval) and \(test.point)")
        }
    }

    func testClampPoint() {
        struct Test {
            let interval: R1Interval
            let point: Double
            let expected: Double
        }

        let tests = [Test(interval: R1Interval(low: 0.1, high: 0.4), point: 0.3, expected: 0.3),
                     Test(interval: R1Interval(low: 0.1, high: 0.4), point: -7, expected: 0.1),
                     Test(interval: R1Interval(low: 0.1, high: 0.4), point: 0.6, expected: 0.4)]

        for test in tests {
            let got = test.interval.clamp(to: test.point)

            XCTAssertEqual(got, test.expected, "with \(test.interval) and \(test.point)")
        }
    }

    func testExpand() {
        struct Test {
            let interval: R1Interval
            let margin: Double
            let expected: R1Interval
        }

        let tests = [Test(interval: i.empty, margin: 0.45, expected: i.empty),
                     Test(interval: i.unit, margin: 0.5, expected: R1Interval(low: -0.5, high: 1.5)),
                     Test(interval: i.unit, margin: -0.5, expected: R1Interval(low: 0.5, high: 0.5)),
                     Test(interval: i.unit, margin: -0.51, expected: i.empty)]

        for test in tests {
            let got = test.interval.expanded(by: test.margin)

            XCTAssertEqual(got, test.expected, "with \(test.interval) and \(test.margin)")
        }
    }
}
