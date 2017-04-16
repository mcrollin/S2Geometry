//
//  S1IntervalTests.swift
//  S2Geometry
//
//  Created by Marc Rollin on 4/11/17.
//  Copyright © 2017 Marc Rollin. All rights reserved.
//

import XCTest
@testable import S2Geometry

// swiftlint:disable nesting line_length function_body_length type_body_length file_length

class S1IntervalTests: XCTestCase {

    let empty: S1Interval = .empty
    let full: S1Interval = .full

    // Single-point intervals
    let zero = S1Interval(point: 0)
    let pi2 = S1Interval(point: .pi / 2)
    let pi = S1Interval(point: .pi)
    let miPi = S1Interval(point: -.pi)  // Same as "pi" after normalization.
    let miPi2 = S1Interval(point: -.pi / 2)

    // Single quadrants
    let quad1 = S1Interval(low: 0, high: .pi / 2)
    let quad2 = S1Interval(low: .pi / 2, high: -.pi)
    let quad3 = S1Interval(low: .pi, high: -.pi / 2)
    let quad4 = S1Interval(low: -.pi / 2, high: 0)

    // Quadrant pairs
    let quad12 = S1Interval(low: 0, high: -.pi)
    let quad23 = S1Interval(low: .pi / 2, high: -.pi / 2)
    let quad34 = S1Interval(low: -.pi, high: 0)
    let quad41 = S1Interval(low: -.pi / 2, high: .pi / 2)

    // Quadrant triples
    let quad123 = S1Interval(low: 0, high: -.pi / 2)
    let quad234 = S1Interval(low: .pi / 2, high: 0)
    let quad341 = S1Interval(low: .pi, high: .pi / 2)
    let quad412 = S1Interval(low: -.pi / 2, high: -.pi)

    // Small intervals around the midpoints between quadrants, such that
    // the center of each interval is offset slightly CCW from the midpoint.
    let mid12 = S1Interval(low: .pi / 2 - 0.01, high: .pi / 2 + 0.02)
    let mid23 = S1Interval(low: .pi - 0.01, high: -.pi + 0.02)
    let mid34 = S1Interval(low: -.pi / 2 - 0.01, high: -.pi / 2 + 0.02)
    let mid41 = S1Interval(low: -0.01, high: 0.02)

    func testStringConversion() {
        struct Test {
            let interval: S1Interval
            let expected: String
        }

        let tests = [Test(interval: S1Interval(low: 42, high: -4.5), expected: "[42.0,-4.5]")]

        for test in tests {
            let got = test.interval.description

            XCTAssertEqual(got, test.expected, "with \(test.interval)")
        }
    }

    func testConstructors() {
        XCTAssertEqual(miPi.low, .pi, "[-π,-π] is not normalized to [π,π]")
        XCTAssertEqual(miPi.high, .pi, "[-π,-π] is not normalized to [π,π]")

        let interval = S1Interval(point: 0)

        XCTAssertTrue(interval.isValid(), "zero value Interval is not valid")

        struct Test {
            let pointA: Double
            let pointB: Double
            let expected: S1Interval
        }

        let tests = [Test(pointA: -.pi, pointB: .pi, expected: pi),
                     Test(pointA: .pi, pointB: -.pi, expected: pi),
                     Test(pointA: mid34.high, pointB: mid34.low, expected: mid34),
                     Test(pointA: mid23.low, pointB: mid23.high, expected: mid23)]

        for test in tests {
            let got = S1Interval(pointA: test.pointA, pointB: test.pointB)

            XCTAssertEqual(got, test.expected, "with \(test.pointA) and \(test.pointB)")
        }
    }

    func testSimplePredicates() {
        XCTAssertTrue(zero.isValid() && !zero.isEmpty() && !zero.isFull(), "zero interval is invalid or empty or full")
        XCTAssertTrue(empty.isValid() && empty.isEmpty() && !empty.isFull(), "empty interval is invalid or not empty or full")
        XCTAssertTrue(empty.isInverted(), "empty interval is not inverted")
        XCTAssertTrue(full.isValid() && !full.isEmpty() && full.isFull(), "full interval is invalid or empty or not full")
        XCTAssertTrue(pi.isValid() && !pi.isEmpty() && !pi.isInverted(), "pi is invalid or empty or inverted")
        XCTAssertTrue(miPi.isValid() && !miPi.isEmpty() && !miPi.isInverted(), "miPi is invalid or empty or inverted")
    }

    func testAlmostFullOrEmpty() {
        // Test that rounding errors don't cause intervals that are almost empty
        // or full to be considered empty or full.
        // The following value is the greatest representable value less than Pi.
        let almostPi = .pi - 2 * Double.epsilon

        XCTAssertFalse(S1Interval(low: -almostPi, high: .pi).isFull(), "should not be full")
        XCTAssertFalse(S1Interval(low: -.pi, high: almostPi).isFull(), "should not be full")
        XCTAssertFalse(S1Interval(low: .pi, high: -almostPi).isEmpty(), "should not be empty")
        XCTAssertFalse(S1Interval(low: almostPi, high: -.pi).isEmpty(), "should not be empty")
    }

    func testCenter() {
        struct Test {
            let interval: S1Interval
            let expected: Double
        }

        let tests = [Test(interval: quad12, expected: .pi / 2),
                     Test(interval: S1Interval(low: 3.1, high: 2.9), expected: 3 - .pi),
                     Test(interval: S1Interval(low: -2.9, high: -3.1), expected: .pi - 3),
                     Test(interval: S1Interval(low: 2.1, high: -2.1), expected: .pi),
                     Test(interval: pi, expected: .pi),
                     Test(interval: miPi, expected: .pi),
                     Test(interval: quad23, expected: .pi),
                     Test(interval: quad123, expected: 0.75 * .pi)]

        for test in tests {
            let got = test.interval.center

            XCTAssertTrue(test.expected ==~ got, "with \(test.interval)")
        }
    }

    func testLength() {
        struct Test {
            let interval: S1Interval
            let expected: Double
        }

        let tests = [Test(interval: empty, expected: -1),
                     Test(interval: quad12, expected: .pi),
                     Test(interval: pi, expected: 0),
                     Test(interval: miPi, expected: 0),
                     Test(interval: quad123, expected: 1.5 * .pi),
                     Test(interval: quad23, expected: .pi),
                     Test(interval: full, expected: 2 * .pi)]

        for test in tests {
            let got = test.interval.length

            XCTAssertTrue(test.expected ==~ got, "with \(test.interval)")
        }
    }

    func testContainsPoint3() {
        struct Test {
            let interval: S1Interval
            let insidePoints: [Double]
            let outsidePoints: [Double]
            let interiorInsidePoints: [Double]
            let interiorOutsidePoints: [Double]
        }

        let tests = [Test(interval: empty,
                          insidePoints: [], outsidePoints: [0, .pi, -.pi],
                          interiorInsidePoints: [], interiorOutsidePoints: [.pi, -.pi]),
                     Test(interval: full,
                          insidePoints: [0, .pi, -.pi], outsidePoints: [],
                          interiorInsidePoints: [.pi, -.pi], interiorOutsidePoints: []),
                     Test(interval: quad12,
                          insidePoints: [0, .pi, -.pi], outsidePoints: [],
                          interiorInsidePoints: [.pi / 2], interiorOutsidePoints: [0, .pi, -.pi]),
                     Test(interval: quad23,
                          insidePoints: [.pi / 2, -.pi / 2, .pi, -.pi], outsidePoints: [0],
                          interiorInsidePoints: [.pi, -.pi], interiorOutsidePoints: [.pi / 2, -.pi / 2, 0]),
                     Test(interval: pi,
                          insidePoints: [.pi, -.pi], outsidePoints: [0],
                          interiorInsidePoints: [], interiorOutsidePoints: [.pi, -.pi]),
                     Test(interval: miPi,
                          insidePoints: [.pi, -.pi], outsidePoints: [0],
                          interiorInsidePoints: [], interiorOutsidePoints: [.pi, -.pi]),
                     Test(interval: zero,
                          insidePoints: [0], outsidePoints: [],
                          interiorInsidePoints: [], interiorOutsidePoints: [0])]

        for test in tests {
            for point in test.insidePoints {
                XCTAssertTrue(test.interval.contains(point: point), "with \(point)")
            }

            for point in test.outsidePoints {
                XCTAssertFalse(test.interval.contains(point: point), "with \(point)")
            }

            for point in test.interiorInsidePoints {
                XCTAssertTrue(test.interval.interiorContains(point: point), "with \(point)")
            }

            for point in test.interiorOutsidePoints {
                XCTAssertFalse(test.interval.interiorContains(point: point), "with \(point)")
            }
        }
    }

    func testIntervalOperations() {
        let quad12Eps = S1Interval(low: quad12.low, high: mid23.high)
        let quad2High = S1Interval(low: mid23.low, high: quad12.high)
        let quad412Eps = S1Interval(low: mid34.low, high: quad12.high)
        let quadEps12 = S1Interval(low: mid41.low, high: quad12.high)
        let quad1Low = S1Interval(low: quad12.low, high: mid41.high)
        let quad2Low = S1Interval(low: quad23.low, high: mid12.high)
        let quad3High = S1Interval(low: mid34.low, high: quad23.high)
        let quadEps23 = S1Interval(low: mid12.low, high: quad23.high)
        let quad23Eps = S1Interval(low: quad23.low, high: mid34.high)
        let quadEps123 = S1Interval(low: mid41.low, high: quad23.high)

        struct Test {
            let x: S1Interval
            let y: S1Interval
            let union: S1Interval
            let intersection: S1Interval
            let contains: Bool
            let interiorContains: Bool
            let intersects: Bool
            let interiorIntersects: Bool
        }

        let tests = [Test(x: empty, y: empty, union: empty, intersection: empty,
                          contains: true, interiorContains: true, intersects: false, interiorIntersects: false),
                     Test(x: empty, y: full, union: full, intersection: empty,
                          contains: false, interiorContains: false, intersects: false, interiorIntersects: false),
                     Test(x: empty, y: zero, union: zero, intersection: empty,
                          contains: false, interiorContains: false, intersects: false, interiorIntersects: false),
                     Test(x: empty, y: pi, union: pi, intersection: empty,
                          contains: false, interiorContains: false, intersects: false, interiorIntersects: false),
                     Test(x: empty, y: miPi, union: miPi, intersection: empty,
                          contains: false, interiorContains: false, intersects: false, interiorIntersects: false),

                     Test(x: full, y: empty, union: full, intersection: empty,
                          contains: true, interiorContains: true, intersects: false, interiorIntersects: false),
                     Test(x: full, y: full, union: full, intersection: full,
                          contains: true, interiorContains: true, intersects: true, interiorIntersects: true),
                     Test(x: full, y: zero, union: full, intersection: zero,
                          contains: true, interiorContains: true, intersects: true, interiorIntersects: true),
                     Test(x: full, y: pi, union: full, intersection: pi,
                          contains: true, interiorContains: true, intersects: true, interiorIntersects: true),
                     Test(x: full, y: quad12, union: full, intersection: quad12,
                          contains: true, interiorContains: true, intersects: true, interiorIntersects: true),
                     Test(x: full, y: quad23, union: full, intersection: quad23,
                          contains: true, interiorContains: true, intersects: true, interiorIntersects: true),

                     Test(x: zero, y: empty, union: zero, intersection: empty,
                          contains: true, interiorContains: true, intersects: false, interiorIntersects: false),
                     Test(x: zero, y: full, union: full, intersection: zero,
                          contains: false, interiorContains: false, intersects: true, interiorIntersects: false),
                     Test(x: zero, y: zero, union: zero, intersection: zero,
                          contains: true, interiorContains: false, intersects: true, interiorIntersects: false),
                     Test(x: zero, y: pi, union: S1Interval(low: 0, high: .pi), intersection: empty,
                          contains: false, interiorContains: false, intersects: false, interiorIntersects: false),
                     Test(x: zero, y: pi2, union: quad1, intersection: empty,
                          contains: false, interiorContains: false, intersects: false, interiorIntersects: false),
                     Test(x: zero, y: miPi, union: quad12, intersection: empty,
                          contains: false, interiorContains: false, intersects: false, interiorIntersects: false),
                     Test(x: zero, y: miPi2, union: quad4, intersection: empty,
                          contains: false, interiorContains: false, intersects: false, interiorIntersects: false),
                     Test(x: zero, y: quad12, union: quad12, intersection: zero,
                          contains: false, interiorContains: false, intersects: true, interiorIntersects: false),
                     Test(x: zero, y: quad23, union: quad123, intersection: empty,
                          contains: false, interiorContains: false, intersects: false, interiorIntersects: false),

                     Test(x: pi2, y: empty, union: pi2, intersection: empty,
                          contains: true, interiorContains: true, intersects: false, interiorIntersects: false),
                     Test(x: pi2, y: full, union: full, intersection: pi2,
                          contains: false, interiorContains: false, intersects: true, interiorIntersects: false),
                     Test(x: pi2, y: zero, union: quad1, intersection: empty,
                          contains: false, interiorContains: false, intersects: false, interiorIntersects: false),
                     Test(x: pi2, y: pi, union: S1Interval(low:.pi / 2, high: .pi), intersection: empty,
                          contains: false, interiorContains: false, intersects: false, interiorIntersects: false),
                     Test(x: pi2, y: pi2, union: pi2, intersection: pi2,
                          contains: true, interiorContains: false, intersects: true, interiorIntersects: false),
                     Test(x: pi2, y: miPi, union: quad2, intersection: empty,
                          contains: false, interiorContains: false, intersects: false, interiorIntersects: false),
                     Test(x: pi2, y: miPi2, union: quad23, intersection: empty,
                          contains: false, interiorContains: false, intersects: false, interiorIntersects: false),
                     Test(x: pi2, y: quad12, union: quad12, intersection: pi2,
                          contains: false, interiorContains: false, intersects: true, interiorIntersects: false),
                     Test(x: pi2, y: quad23, union: quad23, intersection: pi2,
                          contains: false, interiorContains: false, intersects: true, interiorIntersects: false),

                     Test(x: pi, y: empty, union: pi, intersection: empty,
                          contains: true, interiorContains: true, intersects: false, interiorIntersects: false),
                     Test(x: pi, y: full, union: full, intersection: pi,
                          contains: false, interiorContains: false, intersects: true, interiorIntersects: false),
                     Test(x: pi, y: zero, union: S1Interval(low: .pi, high: 0), intersection: empty,
                          contains: false, interiorContains: false, intersects: false, interiorIntersects: false),
                     Test(x: pi, y: pi, union: pi, intersection: pi,
                          contains: true, interiorContains: false, intersects: true, interiorIntersects: false),
                     Test(x: pi, y: pi2, union: S1Interval(low:.pi / 2, high: .pi), intersection: empty,
                          contains: false, interiorContains: false, intersects: false, interiorIntersects: false),
                     Test(x: pi, y: miPi, union: pi, intersection: pi,
                          contains: true, interiorContains: false, intersects: true, interiorIntersects: false),
                     Test(x: pi, y: miPi2, union: quad3, intersection: empty,
                          contains: false, interiorContains: false, intersects: false, interiorIntersects: false),
                     Test(x: pi, y: quad12, union: S1Interval(low: 0, high: .pi), intersection: pi,
                          contains: false, interiorContains: false, intersects: true, interiorIntersects: false),
                     Test(x: pi, y: quad23, union: quad23, intersection: pi,
                          contains: false, interiorContains: false, intersects: true, interiorIntersects: false),

                     Test(x: miPi, y: empty, union: miPi, intersection: empty,
                          contains: true, interiorContains: true, intersects: false, interiorIntersects: false),
                     Test(x: miPi, y: full, union: full, intersection: miPi,
                          contains: false, interiorContains: false, intersects: true, interiorIntersects: false),
                     Test(x: miPi, y: zero, union: quad34, intersection: empty,
                          contains: false, interiorContains: false, intersects: false, interiorIntersects: false),
                     Test(x: miPi, y: pi, union: miPi, intersection: miPi,
                          contains: true, interiorContains: false, intersects: true, interiorIntersects: false),
                     Test(x: miPi, y: pi2, union: quad2, intersection: empty,
                          contains: false, interiorContains: false, intersects: false, interiorIntersects: false),
                     Test(x: miPi, y: miPi, union: miPi, intersection: miPi,
                          contains: true, interiorContains: false, intersects: true, interiorIntersects: false),
                     Test(x: miPi, y: miPi2, union: S1Interval(low: -.pi, high: -.pi / 2), intersection: empty,
                          contains: false, interiorContains: false, intersects: false, interiorIntersects: false),
                     Test(x: miPi, y: quad12, union: quad12, intersection: miPi,
                          contains: false, interiorContains: false, intersects: true, interiorIntersects: false),
                     Test(x: miPi, y: quad23, union: quad23, intersection: miPi,
                          contains: false, interiorContains: false, intersects: true, interiorIntersects: false),

                     Test(x: quad12, y: empty, union: quad12, intersection: empty,
                          contains: true, interiorContains: true, intersects: false, interiorIntersects: false),
                     Test(x: quad12, y: full, union: full, intersection: quad12,
                          contains: false, interiorContains: false, intersects: true, interiorIntersects: true),
                     Test(x: quad12, y: zero, union: quad12, intersection: zero,
                          contains: true, interiorContains: false, intersects: true, interiorIntersects: false),
                     Test(x: quad12, y: pi, union: quad12, intersection: pi,
                          contains: true, interiorContains: false, intersects: true, interiorIntersects: false),
                     Test(x: quad12, y: miPi, union: quad12, intersection: miPi,
                          contains: true, interiorContains: false, intersects: true, interiorIntersects: false),
                     Test(x: quad12, y: quad12, union: quad12, intersection: quad12,
                          contains: true, interiorContains: false, intersects: true, interiorIntersects: true),
                     Test(x: quad12, y: quad23, union: quad123, intersection: quad2,
                          contains: false, interiorContains: false, intersects: true, interiorIntersects: true),
                     Test(x: quad12, y: quad34, union: full, intersection: quad12,
                          contains: false, interiorContains: false, intersects: true, interiorIntersects: false),

                     Test(x: quad23, y: empty, union: quad23, intersection: empty,
                          contains: true, interiorContains: true, intersects: false, interiorIntersects: false),
                     Test(x: quad23, y: full, union: full, intersection: quad23,
                          contains: false, interiorContains: false, intersects: true, interiorIntersects: true),
                     Test(x: quad23, y: zero, union: quad234, intersection: empty,
                          contains: false, interiorContains: false, intersects: false, interiorIntersects: false),
                     Test(x: quad23, y: pi, union: quad23, intersection: pi,
                          contains: true, interiorContains: true, intersects: true, interiorIntersects: true),
                     Test(x: quad23, y: miPi, union: quad23, intersection: miPi,
                          contains: true, interiorContains: true, intersects: true, interiorIntersects: true),
                     Test(x: quad23, y: quad12, union: quad123, intersection: quad2,
                          contains: false, interiorContains: false, intersects: true, interiorIntersects: true),
                     Test(x: quad23, y: quad23, union: quad23, intersection: quad23,
                          contains: true, interiorContains: false, intersects: true, interiorIntersects: true),
                     Test(x: quad23, y: quad34, union: quad234, intersection: S1Interval(low: -.pi, high: -.pi / 2),
                          contains: false, interiorContains: false, intersects: true, interiorIntersects: true),

                     Test(x: quad1, y: quad23, union: quad123, intersection: S1Interval(low: .pi / 2, high: .pi / 2),
                          contains: false, interiorContains: false, intersects: true, interiorIntersects: false),
                     Test(x: quad2, y: quad3, union: quad23, intersection: miPi,
                          contains: false, interiorContains: false, intersects: true, interiorIntersects: false),
                     Test(x: quad3, y: quad2, union: quad23, intersection: pi,
                          contains: false, interiorContains: false, intersects: true, interiorIntersects: false),
                     Test(x: quad2, y: pi, union: quad2, intersection: pi,
                          contains: true, interiorContains: false, intersects: true, interiorIntersects: false),
                     Test(x: quad2, y: miPi, union: quad2, intersection: miPi,
                          contains: true, interiorContains: false, intersects: true, interiorIntersects: false),
                     Test(x: quad3, y: pi, union: quad3, intersection: pi,
                          contains: true, interiorContains: false, intersects: true, interiorIntersects: false),
                     Test(x: quad3, y: miPi, union: quad3, intersection: miPi,
                          contains: true, interiorContains: false, intersects: true, interiorIntersects: false),

                     Test(x: quad12, y: mid12, union: quad12, intersection: mid12,
                          contains: true, interiorContains: true, intersects: true, interiorIntersects: true),
                     Test(x: mid12, y: quad12, union: quad12, intersection: mid12,
                          contains: false, interiorContains: false, intersects: true, interiorIntersects: true),

                     Test(x: quad12, y: mid23, union: quad12Eps, intersection: quad2High,
                          contains: false, interiorContains: false, intersects: true, interiorIntersects: true),
                     Test(x: mid23, y: quad12, union: quad12Eps, intersection: quad2High,
                          contains: false, interiorContains: false, intersects: true, interiorIntersects: true),

                     Test(x: quad12, y: mid34, union: quad412Eps, intersection: empty,
                          contains: false, interiorContains: false, intersects: false, interiorIntersects: false),
                     Test(x: mid34, y: quad12, union: quad412Eps, intersection: empty,
                          contains: false, interiorContains: false, intersects: false, interiorIntersects: false),

                     Test(x: quad12, y: mid41, union: quadEps12, intersection: quad1Low,
                          contains: false, interiorContains: false, intersects: true, interiorIntersects: true),
                     Test(x: mid41, y: quad12, union: quadEps12, intersection: quad1Low,
                          contains: false, interiorContains: false, intersects: true, interiorIntersects: true),

                     Test(x: quad23, y: mid12, union: quadEps23, intersection: quad2Low,
                          contains: false, interiorContains: false, intersects: true, interiorIntersects: true),
                     Test(x: mid12, y: quad23, union: quadEps23, intersection: quad2Low,
                          contains: false, interiorContains: false, intersects: true, interiorIntersects: true),
                     Test(x: quad23, y: mid23, union: quad23, intersection: mid23,
                          contains: true, interiorContains: true, intersects: true, interiorIntersects: true),
                     Test(x: mid23, y: quad23, union: quad23, intersection: mid23,
                          contains: false, interiorContains: false, intersects: true, interiorIntersects: true),
                     Test(x: quad23, y: mid34, union: quad23Eps, intersection: quad3High,
                          contains: false, interiorContains: false, intersects: true, interiorIntersects: true),
                     Test(x: mid34, y: quad23, union: quad23Eps, intersection: quad3High,
                          contains: false, interiorContains: false, intersects: true, interiorIntersects: true),
                     Test(x: quad23, y: mid41, union: quadEps123, intersection: empty,
                          contains: false, interiorContains: false, intersects: false, interiorIntersects: false),
                     Test(x: mid41, y: quad23, union: quadEps123, intersection: empty,
                          contains: false, interiorContains: false, intersects: false, interiorIntersects: false)]

        for test in tests {
            XCTAssertEqual(test.x.contains(interval: test.y), test.contains, "with \(test.x) and \(test.y)")
            XCTAssertEqual(test.x.interiorContains(interval: test.y), test.interiorContains, "with \(test.x) and \(test.y)")
            XCTAssertEqual(test.x.intersects(with: test.y), test.intersects, "with \(test.x) and \(test.y)")
            XCTAssertEqual(test.x.interiorIntersects(with: test.y), test.interiorIntersects, "with \(test.x) and \(test.y)")
            XCTAssertEqual(test.x.union(with: test.y), test.union, "with \(test.x) and \(test.y)")
            XCTAssertEqual(test.x + test.y, test.union, "with \(test.x) and \(test.y)")
            XCTAssertEqual(test.x.intersection(with: test.y), test.intersection, "with \(test.x) and \(test.y)")
        }
    }

    func testAddPoint() {
        struct Test {
            let interval: S1Interval
            let points: [Double]
            let expected: S1Interval
        }

        let tests = [Test(interval: empty, points: [0], expected: zero),
                     Test(interval: empty, points: [1, 0], expected: S1Interval(low: 0, high: 1)),
                     Test(interval: empty, points: [.pi], expected: pi),
                     Test(interval: empty, points: [2 * .pi], expected: empty),
                     Test(interval: empty, points: [-.pi], expected: miPi),
                     Test(interval: empty, points: [.pi, -.pi], expected: pi),
                     Test(interval: empty, points: [-.pi, .pi], expected: miPi),
                     Test(interval: empty, points: [mid12.low, mid12.high], expected: mid12),
                     Test(interval: empty, points: [mid23.low, mid23.high], expected: mid23),

                     Test(interval: quad1, points: [-0.9 * .pi, -.pi / 2], expected: quad123),
                     Test(interval: full, points: [0], expected: full),
                     Test(interval: full, points: [.pi], expected: full),
                     Test(interval: full, points: [-.pi], expected: full)]

        for test in tests {
            let expected = test.expected
            var i = test.interval

            for point in test.points {
                i = i.add(point: point)
            }

            XCTAssertTrue(i.low ==~ expected.low, "with \(test.interval) and \(test.points)")
            XCTAssertTrue(i.high ==~ expected.high, "with \(test.interval) and \(test.points)")
        }
    }

    func testExpanded() {
        struct Test {
            let interval: S1Interval
            let margin: Double
            let expected: S1Interval
        }

        let tests = [Test(interval: empty, margin: 1, expected: empty),
                     Test(interval: full, margin: 1, expected: full),
                     Test(interval: zero, margin: 1, expected: S1Interval(low: -1, high: 1)),
                     Test(interval: miPi, margin: 0.01, expected: S1Interval(low: .pi - 0.01, high: -.pi + 0.01)),
                     Test(interval: pi, margin: 27, expected: full),
                     Test(interval: pi, margin: .pi / 2, expected: quad23),
                     Test(interval: pi2, margin: .pi / 2, expected: quad12),
                     Test(interval: miPi2, margin: .pi / 2, expected: quad34),
                     Test(interval: empty, margin: -1, expected: empty),
                     Test(interval: full, margin: -1, expected: full),
                     Test(interval: quad123, margin: -27, expected: empty),
                     Test(interval: quad234, margin: -27, expected: empty),
                     Test(interval: quad123, margin: -.pi / 2, expected: quad2),
                     Test(interval: quad341, margin: -.pi / 2, expected: quad4),
                     Test(interval: quad412, margin: -.pi / 2, expected: quad1)]

        for test in tests {
            XCTAssertEqual(test.interval.expanded(by: test.margin), test.expected, "with \(test.interval) and \(test.margin)")
        }
    }

    func testInverted() {
        struct Test {
            let interval: S1Interval
            let expected: S1Interval
        }

        let tests = [Test(interval: zero, expected: zero),
                     Test(interval: empty, expected: full),
                     Test(interval: quad12, expected: quad34),
                     Test(interval: pi, expected: pi)]

        for test in tests {
            XCTAssertEqual(test.interval.inverted, test.expected, "with \(test.interval)")
        }
    }
}
