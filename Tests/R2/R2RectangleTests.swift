//
//  R2RectangleTests.swift
//  S2Geometry
//
//  Created by Marc Rollin on 4/9/17.
//  Copyright © 2017 Marc Rollin. All rights reserved.
//

import XCTest
@testable import S2Geometry

// swiftlint:disable nesting line_length function_body_length type_body_length

class R2RectangleTests: XCTestCase {

    let sw = R2Point(x: 0, y: 0.25)
    let se = R2Point(x: 0.5, y: 0.25)
    let ne = R2Point(x: 0.5, y: 0.75)
    let nw = R2Point(x: 0, y: 0.75)

    let empty: R2Rectangle = .empty
    let rectMid = R2Rectangle(points: R2Point(x: 0.25, y: 0.5), R2Point(x: 0.25, y: 0.5))
    var rect: R2Rectangle { return R2Rectangle(points: sw, ne) }
    var rectSW: R2Rectangle { return R2Rectangle(points: sw, sw) }
    var rectNE: R2Rectangle { return R2Rectangle(points: ne, ne) }

    func testStringConversion() {
        struct Test {
            let rectangle: R2Rectangle
            let expected: String
        }

        let tests = [Test(rectangle: R2Rectangle(x: R1Interval(point: 5), y: R1Interval(low: -4, high: 42)),
                          expected: "[low(5.0,-4.0), high(5.0,42.0)]")]

        for test in tests {
            let got = test.rectangle.description

            XCTAssertEqual(got, test.expected, "with \(test.rectangle)")
        }
    }

    func testEmpty() {
        XCTAssertTrue(empty.isValid(), "empty Rectangle should be valid \(empty)")
        XCTAssertTrue(empty.isEmpty(), "empty Rectangle should be empty \(empty)")
    }

    func testFromVariousTypes() {
        struct Test {
            let got: R2Rectangle
            let expected: R2Rectangle
        }

        let identity = R2Rectangle(points: R2Point(x: 0.1, y: 0), R2Point(x: 0.2, y: 0.4))

        let tests = [Test(got: R2Rectangle(center: R2Point(x: 0.3, y: 0.5), size: R2Point(x: 0.2, y: 0.4)),
                          expected: R2Rectangle(points: R2Point(x: 0.2, y: 0.3), R2Point(x: 0.4, y: 0.7))),
                     Test(got: R2Rectangle(center: R2Point(x: 1, y: 0.1), size: R2Point(x: 0, y: 2)),
                          expected: R2Rectangle(points: R2Point(x: 1, y: -0.9), R2Point(x: 1, y: 1.1))),
                     Test(got: identity, expected: R2Rectangle(x: identity.x, y: identity.y)),
                     Test(got: R2Rectangle(points: R2Point(x: 0.15, y: 0.3), R2Point(x: 0.35, y: 0.9)),
                          expected: R2Rectangle(points: R2Point(x: 0.15, y: 0.9), R2Point(x: 0.35, y: 0.9))),
                     Test(got: R2Rectangle(points: R2Point(x: 0.12, y: 0), R2Point(x: 0.83, y: 0.5)),
                          expected: R2Rectangle(points: R2Point(x: 0.83, y: 0), R2Point(x: 0.12, y: 0.5))),
                     Test(got: R2Rectangle(), expected: empty)]

        for test in tests {
            XCTAssertTrue(test.got ==~ test.expected, "with \(test.got) and  \(test.expected)")
        }
    }

    func testCenter() {
        struct Test {
            let rectangle: R2Rectangle
            let expected: R2Point
        }

        let tests = [Test(rectangle: empty, expected: R2Point(x: 0.5, y: 0.5)),
                     Test(rectangle: rect, expected: R2Point(x: 0.25, y: 0.5))]

        for test in tests {
            let got = test.rectangle.center

            XCTAssertEqual(got, test.expected, "with \(test.rectangle) and  \(test.expected)")
        }
    }

    func testSize() {
        struct Test {
            let rectangle: R2Rectangle
            let expected: R2Point
        }

        let tests = [Test(rectangle: empty, expected: R2Point(x: -1.0, y: -1.0)),
                     Test(rectangle: rect, expected: R2Point(x: 0.5, y: 0.5))]

        for test in tests {
            let got = test.rectangle.size

            XCTAssertEqual(got, test.expected, "with \(test.rectangle) and  \(test.expected)")
        }
    }

    func testVertices() {
        let points = [sw, se, ne, nw]
        let vertices = rect.vertices

        XCTAssertEqual(vertices, points, "with \(vertices) and  \(points)")
    }

    func testVertex() {
        struct Test {
            let rectangle: R2Rectangle
            let expected: R2Point
        }

        let tests = [Test(rectangle: empty, expected: R2Point(x: 1.0, y: 1.0)),
                     Test(rectangle: rect, expected: R2Point(x: 0.0, y: 0.25))]

        for test in tests {
            let got = test.rectangle.vertex(i: 12, j: -4)

            XCTAssertEqual(got, test.expected, "with \(test.rectangle) and  \(test.expected)")
        }
    }

    func testContainsPoint() {
        struct Test {
            let rectangle: R2Rectangle
            let point: R2Point
            let expected: Bool
        }

        let tests = [Test(rectangle: rect, point: R2Point(x: 0.2, y: 0.4), expected: true),
                     Test(rectangle: rect, point: R2Point(x: 0.2, y: 0.8), expected: false),
                     Test(rectangle: rect, point: R2Point(x: -0.1, y: 0.4), expected: false),
                     Test(rectangle: rect, point: R2Point(x: 0.6, y: 0.4), expected: false),
                     Test(rectangle: rect, point: R2Point(x: rect.x.low, y: rect.y.low), expected: true),
                     Test(rectangle: rect, point: R2Point(x: rect.x.high, y: rect.y.high), expected: true)]

        for test in tests {
            let got = test.rectangle.contains(point: test.point)

            XCTAssertEqual(got, test.expected, "with \(test.rectangle) and  \(test.point)")
        }
    }

    func testInteriorContainsPoint() {
        struct Test {
            let rectangle: R2Rectangle
            let point: R2Point
            let expected: Bool
        }

        let tests = [Test(rectangle: rect, point: sw, expected: false), // Check corners are not contained.
            Test(rectangle: rect, point: ne, expected: false),
            Test(rectangle: rect, point: R2Point(x: 0, y: 0.5), expected: false), // Check a point on the border is not contained.
            Test(rectangle: rect, point: R2Point(x: 0.25, y: 0.25), expected: false),
            Test(rectangle: rect, point: R2Point(x: 0.5, y: 0.5), expected: false),
            Test(rectangle: rect, point: R2Point(x: 0.125, y: 0.6), expected: true)] // Check points inside are contained.

        for test in tests {
            let got = test.rectangle.interiorContains(point: test.point)

            XCTAssertEqual(got, test.expected, "with \(test.rectangle) and  \(test.point)")
        }
    }

    func testOperations() {
        struct Test {
            let rect1: R2Rectangle
            let rect2: R2Rectangle
            let contains: Bool
            let interiorContains: Bool
            let intersects: Bool
            let interiorIntersects: Bool
            let union: R2Rectangle
            let intersection: R2Rectangle
        }

        let tests = [Test(rect1: rect, rect2: rectMid,
                          contains: true, interiorContains: true, intersects: true, interiorIntersects: true,
                          union: rect, intersection: rectMid),
                     Test(rect1: rect, rect2: rectSW,
                          contains: true, interiorContains: false, intersects: true, interiorIntersects: false,
                          union: rect, intersection: rectSW),
                     Test(rect1: rect, rect2: rectNE,
                          contains: true, interiorContains: false, intersects: true, interiorIntersects: false,
                          union: rect, intersection: rectNE),
                     Test(rect1: rect, rect2: R2Rectangle(points: R2Point(x: 0.45, y: 0.1), R2Point(x: 0.75, y: 0.3)),
                          contains: false, interiorContains: false, intersects: true, interiorIntersects: true,
                          union: R2Rectangle(points: R2Point(x: 0, y: 0.1), R2Point(x: 0.75, y: 0.75)),
                          intersection: R2Rectangle(points: R2Point(x: 0.45, y: 0.25), R2Point(x: 0.5, y: 0.3))),
                     Test(rect1: rect, rect2: R2Rectangle(points: R2Point(x: 0.5, y: 0.1), R2Point(x: 0.7, y: 0.3)),
                          contains: false, interiorContains: false, intersects: true, interiorIntersects: false,
                          union: R2Rectangle(points: R2Point(x: 0, y: 0.1), R2Point(x: 0.7, y: 0.75)),
                          intersection: R2Rectangle(points: R2Point(x: 0.5, y: 0.25), R2Point(x: 0.5, y: 0.3))),
                     Test(rect1: rect, rect2: R2Rectangle(points: R2Point(x: 0.45, y: 0.1), R2Point(x: 0.7, y: 0.25)),
                          contains: false, interiorContains: false, intersects: true, interiorIntersects: false,
                          union: R2Rectangle(points: R2Point(x: 0, y: 0.1), R2Point(x: 0.7, y: 0.75)),
                          intersection: R2Rectangle(points: R2Point(x: 0.45, y: 0.25), R2Point(x: 0.5, y: 0.25))),
                     Test(rect1: R2Rectangle(points: R2Point(x: 0.1, y: 0.2), R2Point(x: 0.1, y: 0.3)),
                          rect2: R2Rectangle(points: R2Point(x: 0.15, y: 0.7), R2Point(x: 0.2, y: 0.8)),
                          contains: false, interiorContains: false, intersects: false, interiorIntersects: false,
                          union: R2Rectangle(points: R2Point(x: 0.1, y: 0.2), R2Point(x: 0.2, y: 0.8)),
                          intersection: empty),
                     Test(rect1: R2Rectangle(points: R2Point(x: 0.1, y: 0.2), R2Point(x: 0.4, y: 0.5)),
                          rect2: R2Rectangle(points: R2Point(x: 0, y: 0), R2Point(x: 0.2, y: 0.1)),
                          contains: false, interiorContains: false, intersects: false, interiorIntersects: false,
                          union: R2Rectangle(points: R2Point(x: 0, y: 0), R2Point(x: 0.4, y: 0.5)),
                          intersection: empty),
                     Test(rect1: R2Rectangle(points: R2Point(x: 0, y: 0), R2Point(x: 0.1, y: 0.3)),
                          rect2: R2Rectangle(points: R2Point(x: 0.2, y: 0.1), R2Point(x: 0.3, y: 0.4)),
                          contains: false, interiorContains: false, intersects: false, interiorIntersects: false,
                          union: R2Rectangle(points: R2Point(x: 0, y: 0), R2Point(x: 0.3, y: 0.4)),
                          intersection: empty)]

        for test in tests {
            let contains = test.rect1.contains(rectangle: test.rect2)
            let interiorContains = test.rect1.interiorContains(rectangle: test.rect2)
            let intersects = test.rect1.intersects(with: test.rect2)
            let interiorIntersects = test.rect1.interiorIntersects(with: test.rect2)
            let union = test.rect1.union(with: test.rect2)
            let intersection = test.rect1.intersection(with: test.rect2)
            let added = test.rect1 + test.rect2

            XCTAssertEqual(contains, test.contains, "with \(test.rect1) and  \(test.rect2)")
            XCTAssertEqual(interiorContains, test.interiorContains, "with \(test.rect1) and  \(test.rect2)")
            XCTAssertEqual(intersects, test.intersects, "with \(test.rect1) and  \(test.rect2)")
            XCTAssertEqual(interiorIntersects, test.interiorIntersects, "with \(test.rect1) and  \(test.rect2)")
            XCTAssertEqual((union ==~ test.rect1), contains, "with \(test.rect1) and  \(test.rect2)")
            XCTAssertNotEqual(intersection.isEmpty(), intersects, "with \(test.rect1) and  \(test.rect2)")
            XCTAssertEqual(union, test.union, "with \(test.rect1) and  \(test.rect2)")
            XCTAssertEqual(intersection, test.intersection, "with \(test.rect1) and  \(test.rect2)")
            XCTAssertEqual(added, test.union, "with \(test.rect1) and  \(test.rect2)")
        }
    }

    func testAddPoints() {
        let rect1 = rect
        var rect2: R2Rectangle = .empty

        rect2 = rect2.add(point: sw)
        rect2 = rect2.add(point: se)
        rect2 = rect2.add(point: nw)
        rect2 = rect2.add(point: R2Point(x: 0.1, y: 0.4))

        XCTAssertTrue(rect1 ==~ rect2, "with \(rect1) and  \(rect2)")
    }

    func testClampPoint() {
        let rect = R2Rectangle(x: R1Interval(low: 0, high: 0.5), y: R1Interval(low: 0.25, high: 0.75))

        struct Test {
            let point: R2Point
            let expected: R2Point
        }

        let tests = [Test(point: R2Point(x: -0.01, y: 0.24), expected: R2Point(x: 0, y: 0.25)),
                     Test(point: R2Point(x: -5, y: 0.48), expected: R2Point(x: 0, y: 0.48)),
                     Test(point: R2Point(x: -5, y: 2.48), expected: R2Point(x: 0, y: 0.75)),
                     Test(point: R2Point(x: 0.19, y: 2.48), expected: R2Point(x: 0.19, y: 0.75)),
                     Test(point: R2Point(x: 6.19, y: 2.48), expected: R2Point(x: 0.5, y: 0.75)),
                     Test(point: R2Point(x: 6.19, y: 0.53), expected: R2Point(x: 0.5, y: 0.53)),
                     Test(point: R2Point(x: 6.19, y: -2.53), expected: R2Point(x: 0.5, y: 0.25)),
                     Test(point: R2Point(x: 0.33, y: -2.53), expected: R2Point(x: 0.33, y: 0.25)),
                     Test(point: R2Point(x: 0.33, y: 0.37), expected: R2Point(x: 0.33, y: 0.37))]

        for test in tests {
            let got = rect.clamp(to: test.point)

            XCTAssertEqual(got, test.expected, "with \(test.point) and  \(test.expected)")
        }
    }

    func testExpandedEmpty() {
        struct Test {
            let rectangle: R2Rectangle
            let point: R2Point
        }

        let tests = [Test(rectangle: empty, point: R2Point(x: 0.1, y: 0.3)),
                     Test(rectangle: empty, point: R2Point(x: -0.1, y: -0.3)),
                     Test(rectangle: R2Rectangle(points: R2Point(x: 0.2, y: 0.4), R2Point(x: 0.3, y: 0.7)),
                          point: R2Point(x: -0.1, y: 0.3)),
                     Test(rectangle: R2Rectangle(points: R2Point(x: 0.2, y: 0.4), R2Point(x: 0.3, y: 0.7)),
                          point: R2Point(x: 0.1, y: -0.2))]

        for test in tests {
            let got = test.rectangle.expanded(margin: test.point)

            XCTAssertTrue(got.isEmpty(), "with \(test.rectangle) and  \(test.point)")
        }
    }

    func testExpandedPoint() {
        struct Test {
            let rectangle: R2Rectangle
            let point: R2Point
            let expected: R2Rectangle
        }

        let tests = [Test(rectangle: R2Rectangle(points: R2Point(x: 0.2, y: 0.4), R2Point(x: 0.3, y: 0.7)),
                          point: R2Point(x: 0.1, y: 0.3),
                          expected: R2Rectangle(points: R2Point(x: 0.1, y: 0.1), R2Point(x: 0.4, y: 1))),
                     Test(rectangle: R2Rectangle(points: R2Point(x: 0.2, y: 0.4), R2Point(x: 0.3, y: 0.7)),
                          point: R2Point(x: 0.1, y: -0.1),
                          expected: R2Rectangle(points: R2Point(x: 0.1, y: 0.5), R2Point(x: 0.4, y: 0.6))),
                     Test(rectangle: R2Rectangle(points: R2Point(x: 0.2, y: 0.4), R2Point(x: 0.3, y: 0.7)),
                          point: R2Point(x: 0.1, y: 0.1),
                          expected: R2Rectangle(points: R2Point(x: 0.1, y: 0.3), R2Point(x: 0.4, y: 0.8)))]

        for test in tests {
            let got = test.rectangle.expanded(margin: test.point)

            XCTAssertEqual(got, test.expected, "with \(test.rectangle) and  \(test.point)")
        }
    }

    func testExpandedMargin() {
        struct Test {
            let rectangle: R2Rectangle
            let margin: Double
            let expected: R2Rectangle
        }

        let tests = [Test(rectangle: R2Rectangle(points: R2Point(x: 0.2, y: 0.4), R2Point(x: 0.3, y: 0.7)),
                          margin: 0.1,
                          expected: R2Rectangle(points: R2Point(x: 0.1, y: 0.3), R2Point(x: 0.4, y: 0.8))),
                     Test(rectangle: R2Rectangle(points: R2Point(x: 0.2, y: 0.4), R2Point(x: 0.3, y: 0.7)),
                          margin: -0.1,
                          expected: empty)]

        for test in tests {
            let got = test.rectangle.expanded(margin: test.margin)

            XCTAssertEqual(got, test.expected, "with \(test.rectangle) and  \(test.margin)")
        }
    }
}
