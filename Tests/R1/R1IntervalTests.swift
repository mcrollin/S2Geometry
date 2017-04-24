//
//  R1IntervalTests.swift
//  S2Geometry
//
//  Created by Marc Rollin on 4/8/17.
//  Copyright © 2017 Marc Rollin. All rights reserved.
//

// swiftlint:disable line_length function_body_length type_body_length

@testable import S2Geometry
import XCTest

class R1IntervalTests: XCTestCase {

    let unit = R1Interval(low: 0, high: 1)
    let negativeUnit = R1Interval(low: -1, high: 0)
    let half = R1Interval(low: 0.5, high: 0.5)
    let empty: R1Interval = .empty

    func testStringConversion() {
        typealias Test = (interval: R1Interval, expected: String)

        let tests = [Test(interval: R1Interval(low: 2, high: 4.5), expected: "[low:2.0, high:4.5]")]

        for test in tests {
            let got = test.interval.description

            XCTAssertEqual(got, test.expected, "with \(test.interval)")
        }
    }

    func testAlmostEqual() {
        typealias Test = (interval: R1Interval, other: R1Interval, expected: Bool)

        let tests = [
            Test(interval: empty, other: empty, expected: true),
            Test(interval: R1Interval(point: 0), other: empty, expected: true),
            Test(interval: empty, other: R1Interval(point: 0), expected: true),
            Test(interval: R1Interval(point: 1), other: empty, expected: true),
            Test(interval: empty, other: R1Interval(point: 1), expected: true),
            Test(interval: empty, other: R1Interval(low: 0, high: 1), expected: false),
            Test(interval: empty, other: R1Interval(low: 1, high: 1 + 2 * .epsilon), expected: true),

            Test(interval: R1Interval(point: 1), other: R1Interval(point: 1), expected: true),
            Test(interval: R1Interval(point: 1), other: R1Interval(low: 1 - .epsilon, high: 1 - .epsilon), expected: true),
            Test(interval: R1Interval(point: 1), other: R1Interval(low: 1 + .epsilon, high: 1 + .epsilon), expected: true),
            Test(interval: R1Interval(point: 1), other: R1Interval(low: 1 - 3 * .epsilon, high: 1), expected: false),
            Test(interval: R1Interval(point: 1), other: R1Interval(low: 1, high: 1 + 3 * .epsilon), expected: false),
            Test(interval: R1Interval(point: 1), other: R1Interval(low: 1 - .epsilon, high: 1 + .epsilon), expected: true),
            Test(interval: R1Interval(point: 0), other: R1Interval(point: 1), expected: false),

            Test(interval: R1Interval(low: 1 - .epsilon, high: 2 + .epsilon), other: R1Interval(low: 1, high: 2), expected: true),
            Test(interval: R1Interval(low: 1 + .epsilon, high: 2 - .epsilon), other: R1Interval(low: 1, high: 2), expected: true),
            Test(interval: R1Interval(low: 1 - 3 * .epsilon, high: 2 + .epsilon), other: R1Interval(low: 1, high: 2), expected: false),
            Test(interval: R1Interval(low: 1 + 3 * .epsilon, high: 2 - .epsilon), other: R1Interval(low: 1, high: 2), expected: false),
            Test(interval: R1Interval(low: 1 - .epsilon, high: 2 + 3 * .epsilon), other: R1Interval(low: 1, high: 2), expected: false),
            Test(interval: R1Interval(low: 1 + .epsilon, high: 2 - 3 * .epsilon), other: R1Interval(low: 1, high: 2), expected: false)
        ]

        for test in tests {
            let got = test.interval ==~ test.other

            XCTAssertEqual(got, test.expected, "with \(test.interval) and \(test.other)")
        }
    }

    func testIsEmpty() {
        XCTAssertFalse(unit.isEmpty, "\(unit) should not be empty")
        XCTAssertFalse(negativeUnit.isEmpty, "\(negativeUnit) should not be empty")
        XCTAssertFalse(half.isEmpty, "\(half) should not be empty")
        XCTAssert(empty.isEmpty, "\(empty) should be empty")
    }

    func testCenter() {
        typealias Test = (interval: R1Interval, expected: Double)

        let tests = [
            Test(interval: unit, expected: 0.5),
            Test(interval: negativeUnit, expected: -0.5),
            Test(interval: half, expected: 0.5)
        ]

        for test in tests {
            let got = test.interval.center

            XCTAssertEqual(got, test.expected, "with \(test.interval)")
        }
    }

    func testLength() {
        typealias Test = (interval: R1Interval, expected: Double)

        let tests = [
            Test(interval: unit, expected: 1),
            Test(interval: negativeUnit, expected: 1),
            Test(interval: half, expected: 0)
        ]

        for test in tests {
            let got = test.interval.length

            XCTAssertEqual(got, test.expected, "with \(test.interval)")
        }
    }

    func testIntervalPointOperations() {
        typealias Test = (interval: R1Interval, point: Double, contains: Bool, interiorContains: Bool)

        let tests = [Test(interval: unit, point: 0.5, contains: true, interiorContains: true)]

        for test in tests {
            let contains = test.interval.contains(point: test.point)
            let interiorContains = test.interval.interiorContains(point: test.point)

            XCTAssertEqual(contains, test.contains, "with \(test.interval)")
            XCTAssertEqual(interiorContains, test.interiorContains, "with \(test.interval)")
        }
    }

    func testIntervalsOperations() {
        typealias Test = (interval: R1Interval, other: R1Interval, contains: Bool,
                          interiorContains: Bool, intersects: Bool, interiorIntersects: Bool)

        let tests = [
            Test(interval: empty, other: empty,
                 contains: true, interiorContains: true,
                 intersects: false, interiorIntersects: false),
            Test(interval: empty, other: unit,
                 contains: false, interiorContains: false,
                 intersects: false, interiorIntersects: false),
            Test(interval: unit, other: half,
                 contains: true, interiorContains: true,
                 intersects: true, interiorIntersects: true),
            Test(interval: unit, other: unit,
                 contains: true, interiorContains: false,
                 intersects: true, interiorIntersects: true),
            Test(interval: unit, other: empty,
                 contains: true, interiorContains: true,
                 intersects: false, interiorIntersects: false),
            Test(interval: unit, other: negativeUnit,
                 contains: false, interiorContains: false,
                 intersects: true, interiorIntersects: false),
            Test(interval: unit, other: R1Interval(low: 0, high: 0.5),
                 contains: true, interiorContains: false,
                 intersects: true, interiorIntersects: true),
            Test(interval: half, other: R1Interval(low: 0, high: 0.5),
                 contains: false, interiorContains: false,
                 intersects: true, interiorIntersects: false),
            Test(interval: R1Interval(low: 1, high: 2.1),
                 other: R1Interval(low: 2, high: 1.9),
                 contains: true, interiorContains: true,
                 intersects: false, interiorIntersects: false)
        ]

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
        typealias Test = (x: R1Interval, y: R1Interval, expected: R1Interval)

        let tests = [
            Test(x: unit, y: half, expected: half),
            Test(x: unit, y: negativeUnit, expected: R1Interval(low: 0, high: 0)),
            Test(x: negativeUnit, y: half, expected: empty),
            Test(x: unit, y: empty, expected: empty),
            Test(x: empty, y: unit, expected: empty)
        ]

        for test in tests {
            let got = test.x.intersection(with: test.y)

            XCTAssertEqual(got, test.expected, "with \(test.x) and \(test.y)")
        }
    }

    func testUnion() {
        typealias Test = (x: R1Interval, y: R1Interval, expected: R1Interval)

        let tests = [
            Test(x: R1Interval(low: 99, high: 100), y: empty, expected: R1Interval(low: 99, high: 100)),
            Test(x: empty, y: R1Interval(low: 99, high: 100), expected: R1Interval(low: 99, high: 100)),
            Test(x: R1Interval(low: 5, high: 3), y: R1Interval(low: 0, high: -2), expected: empty),
            Test(x: R1Interval(low: 0, high: -2), y: R1Interval(low: 5, high: 3), expected: empty),
            Test(x: unit, y: unit, expected: unit),
            Test(x: unit, y: negativeUnit, expected: R1Interval(low: -1, high: 1)),
            Test(x: negativeUnit, y: unit, expected: R1Interval(low: -1, high: 1)),
            Test(x: half, y: unit, expected: unit)
        ]

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
        typealias Test = (interval: R1Interval, point: Double, expected: R1Interval)

        let tests = [
            Test(interval: .empty, point: 5, expected: R1Interval(low: 5, high: 5)),
            Test(interval: R1Interval(point: 5), point: -1, expected: R1Interval(low: -1, high: 5)),
            Test(interval: R1Interval(low: -1, high: 5), point: 0, expected: R1Interval(low: -1, high: 5)),
            Test(interval: R1Interval(low: -1, high: 5), point: 6, expected: R1Interval(low: -1, high: 6))
        ]

        for test in tests {
            let got = test.interval.add(point: test.point)

            XCTAssertEqual(got, test.expected, "with \(test.interval) and \(test.point)")
        }
    }

    func testClampPoint() {
        typealias Test = (interval: R1Interval, point: Double, expected: Double)

        let tests = [
            Test(interval: R1Interval(low: 0.1, high: 0.4), point: 0.3, expected: 0.3),
            Test(interval: R1Interval(low: 0.1, high: 0.4), point: -7, expected: 0.1),
            Test(interval: R1Interval(low: 0.1, high: 0.4), point: 0.6, expected: 0.4)
        ]

        for test in tests {
            let got = test.interval.clamp(to: test.point)

            XCTAssertEqual(got, test.expected, "with \(test.interval) and \(test.point)")
        }
    }

    func testExpand() {
        typealias Test = (interval: R1Interval, margin: Double, expected: R1Interval)

        let tests = [
            Test(interval: empty, margin: 0.45, expected: empty),
            Test(interval: unit, margin: 0.5, expected: R1Interval(low: -0.5, high: 1.5)),
            Test(interval: unit, margin: -0.5, expected: R1Interval(low: 0.5, high: 0.5)),
            Test(interval: unit, margin: -0.51, expected: empty)
        ]

        for test in tests {
            let got = test.interval.expanded(by: test.margin)

            XCTAssertEqual(got, test.expected, "with \(test.interval) and \(test.margin)")
        }
    }
}
