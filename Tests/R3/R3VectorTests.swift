//
//  VectorTests.swift
//  S2Geometry
//
//  Created by Marc Rollin on 4/10/17.
//  Copyright © 2017 Marc Rollin. All rights reserved.
//

import XCTest
@testable import S2Geometry

// swiftlint:disable nesting line_length type_body_length

class R3VectorTests: XCTestCase {

    func testStringConversion() {
        struct Test {
            let vector: R3Vector
            let expected: String
        }

        let tests = [Test(vector: R3Vector(x: 2, y: 4.5, z: -3), expected: "(2.0,4.5,-3.0)")]

        for test in tests {
            let got = test.vector.description

            XCTAssertEqual(got, test.expected, "with \(test.vector)")
        }
    }

    func testVectorNormal() {
        struct Test {
            let vector: R3Vector
            let expected: Double
        }

        let tests = [Test(vector: R3Vector(x: 0, y: 0, z: 0), expected: 0),
                     Test(vector: R3Vector(x: 0, y: 1, z: 0), expected: 1),
                     Test(vector: R3Vector(x: 3, y: -4, z: 12), expected: 13),
                     Test(vector: R3Vector(x: 1, y: 1e-16, z: 1e-32), expected: 1)]

        for test in tests {
            let got = test.vector.normal

            XCTAssertTrue(got ==~ test.expected, "with \(test.vector)")
        }
    }

    func testVectorNormal2() {
        struct Test {
            let vector: R3Vector
            let expected: Double
        }

        let tests = [Test(vector: R3Vector(x: 0, y: 0, z: 0), expected: 0),
                     Test(vector: R3Vector(x: 0, y: 1, z: 0), expected: 1),
                     Test(vector: R3Vector(x: 1, y: 1, z: 1), expected: 3),
                     Test(vector: R3Vector(x: 1, y: 2, z: 3), expected: 14),
                     Test(vector: R3Vector(x: 3, y: -4, z: 12), expected: 169),
                     Test(vector: R3Vector(x: 1, y: 1e-16, z: 1e-32), expected: 1)]

        for test in tests {
            let got = test.vector.normal2

            XCTAssertTrue(got ==~ test.expected, "with \(test.vector)")
        }
    }

    func testVectorNormalized() {
        let vectors = [R3Vector(x: 0, y: 0, z: 0),
                       R3Vector(x: 1, y: 0, z: 0),
                       R3Vector(x: 0, y: 1, z: 0),
                       R3Vector(x: 0, y: 0, z: 1),
                       R3Vector(x: 1, y: 1, z: 1),
                       R3Vector(x: 1, y: 1e-16, z: 1e-32),
                       R3Vector(x: 12.34, y: 56.78, z: 91.01)]

        for vector in vectors {
            let normalized = vector.normalized

            XCTAssertTrue((vector.x *  normalized.y) ==~ (vector.y *  normalized.x), "did not preserve direction with \(vector)")
            XCTAssertTrue((vector.x *  normalized.z) ==~ (vector.z *  normalized.x), "did not preserve direction with \(vector)")

            let isEmpty = [vector.x, vector.y, vector.z]
                .filter { $0 != 0 }.count == 0

            if !isEmpty {
                XCTAssertTrue(normalized.normal ==~ 1, "invalid normal with \(vector)")
            } else {
                XCTAssertEqual(normalized.normal, 0, "invalid normal with \(vector)")
            }
        }
    }

    func testVectorIsUnit() {
        struct Test {
            let vector: R3Vector
            let expected: Bool
        }

        let tests = [Test(vector: R3Vector(x: 0, y: 0, z: 0), expected: false),
                     Test(vector: R3Vector(x: 0, y: 1, z: 0), expected: true),
                     Test(vector: R3Vector(x: 1 + 2 * .epsilon, y: 0, z: 0), expected: true),
                     Test(vector: R3Vector(x: 1 + .epsilon, y: 0, z: 0), expected: true),
                     Test(vector: R3Vector(x: 1, y: 1, z: 1), expected: false),
                     Test(vector: R3Vector(x: 1, y: 1e-16, z: 1e-32), expected: true)]

        for test in tests {
            let got = test.vector.isUnit()

            XCTAssertEqual(got, test.expected, "with \(test.vector)")
        }
    }

    func testDotProduct() {
        struct Test {
            let vector1: R3Vector
            let vector2: R3Vector
            let expected: Double
        }

        let tests = [Test(vector1: R3Vector(x: 1, y:0, z:0), vector2: R3Vector(x: 1, y:0, z:0), expected: 1),
                     Test(vector1: R3Vector(x: 1, y:0, z:0), vector2: R3Vector(x: 0, y:1, z:0), expected: 0),
                     Test(vector1: R3Vector(x: 1, y:0, z:0), vector2: R3Vector(x: 0, y:1, z:1), expected: 0),
                     Test(vector1: R3Vector(x: 1, y:1, z:1), vector2: R3Vector(x: -1, y:-1, z:-1), expected: -3),
                     Test(vector1: R3Vector(x: 1, y:2, z:2), vector2: R3Vector(x: -0.3, y:0.4, z:-1.2), expected: -1.9)]

        for test in tests {
            let got1 = test.vector1.dotProduct(with: test.vector2)
            let got2 = test.vector2.dotProduct(with: test.vector1)

            XCTAssertEqual(got1, test.expected, "with \(test.vector1) and  \(test.vector2)")
            XCTAssertEqual(got2, test.expected, "with \(test.vector1) and  \(test.vector2)")
        }
    }

    func testCrossProduct() {
        struct Test {
            let vector1: R3Vector
            let vector2: R3Vector
            let expected: R3Vector
        }

        let tests = [Test(vector1: R3Vector(x: 1, y:0, z:0), vector2: R3Vector(x: 1, y:0, z:0), expected: R3Vector(x: 0, y:0, z:0)),
                     Test(vector1: R3Vector(x: 1, y:0, z:0), vector2: R3Vector(x: 0, y:1, z:0), expected: R3Vector(x: 0, y:0, z:1)),
                     Test(vector1: R3Vector(x: 0, y:1, z:0), vector2: R3Vector(x: 1, y:0, z:0), expected: R3Vector(x: 0, y:0, z:-1)),
                     Test(vector1: R3Vector(x: 1, y:2, z:3), vector2: R3Vector(x: -4, y:5, z:-6), expected: R3Vector(x: -27, y:-6, z:13))]

        for test in tests {
            let got = test.vector1.crossProduct(with: test.vector2)

            XCTAssertEqual(got, test.expected, "with \(test.vector1) and  \(test.vector2)")
        }
    }

    func testAdd() {
        struct Test {
            let vector1: R3Vector
            let vector2: R3Vector
            let expected: R3Vector
        }

        let tests = [Test(vector1: R3Vector(x: 0, y: 0, z: 0), vector2: R3Vector(x: 0, y: 0, z: 0), expected: R3Vector(x: 0, y: 0, z: 0)),
                     Test(vector1: R3Vector(x: 1, y: 0, z: 0), vector2: R3Vector(x: 0, y: 0, z: 0), expected: R3Vector(x: 1, y: 0, z: 0)),
                     Test(vector1: R3Vector(x: 1, y: 2, z: 3), vector2: R3Vector(x: 4, y: 5, z: 7), expected: R3Vector(x: 5, y: 7, z: 10)),
                     Test(vector1: R3Vector(x: 1, y: -3, z: 5), vector2: R3Vector(x: 1, y: -6, z: -6), expected: R3Vector(x: 2, y: -9, z: -1))]

        for test in tests {
            let got = test.vector1 + test.vector2

            XCTAssertEqual(got, test.expected, "with \(test.vector1) and  \(test.vector2)")
        }
    }

    func testSubstract() {
        struct Test {
            let vector1: R3Vector
            let vector2: R3Vector
            let expected: R3Vector
        }

        let tests = [Test(vector1: R3Vector(x: 0, y: 0, z: 0), vector2: R3Vector(x: 0, y: 0, z: 0), expected: R3Vector(x: 0, y: 0, z: 0)),
                     Test(vector1: R3Vector(x: 1, y: 0, z: 0), vector2: R3Vector(x: 0, y: 0, z: 0), expected: R3Vector(x: 1, y: 0, z: 0)),
                     Test(vector1: R3Vector(x: 1, y: 2, z: 3), vector2: R3Vector(x: 4, y: 5, z: 7), expected: R3Vector(x: -3, y: -3, z: -4)),
                     Test(vector1: R3Vector(x: 1, y: -3, z: 5), vector2: R3Vector(x: 1, y: -6, z: -6), expected: R3Vector(x: 0, y: 3, z: 11))]

        for test in tests {
            let got = test.vector1 - test.vector2

            XCTAssertEqual(got, test.expected, "with \(test.vector1) and  \(test.vector2)")
        }
    }

    func testMultiply() {
        struct Test {
            let vector: R3Vector
            let multiplier: Double
            let expected: R3Vector
        }

        let tests = [Test(vector: R3Vector(x: 0, y: 0, z: 0), multiplier: 3, expected: R3Vector(x: 0, y: 0, z: 0)),
                     Test(vector: R3Vector(x: 1, y: 0, z: 0), multiplier: 1, expected: R3Vector(x: 1, y: 0, z: 0)),
                     Test(vector: R3Vector(x: 1, y: 0, z: 0), multiplier: 0, expected: R3Vector(x: 0, y: 0, z: 0)),
                     Test(vector: R3Vector(x: 1, y: 0, z: 0), multiplier: 3, expected: R3Vector(x: 3, y: 0, z: 0)),
                     Test(vector: R3Vector(x: 1, y: -3, z: 5), multiplier: -1, expected: R3Vector(x: -1, y: 3, z: -5)),
                     Test(vector: R3Vector(x: 1, y: -3, z: 5), multiplier: 2, expected: R3Vector(x: 2, y: -6, z: 10))]

        for test in tests {
            let got1 = test.vector * test.multiplier
            let got2 = test.multiplier * test.vector

            XCTAssertTrue(got1 ==~ test.expected, "with \(test.vector) and  \(test.multiplier)")
            XCTAssertTrue(got1 ==~ got2, "with \(test.vector) and  \(test.multiplier)")
        }
    }

    func testDistance() {
        struct Test {
            let vector1: R3Vector
            let vector2: R3Vector
            let expected: Double
        }

        let tests = [Test(vector1: R3Vector(x: 1, y: 0, z: 0), vector2: R3Vector(x: 1, y: 0, z: 0), expected: 0),
                     Test(vector1: R3Vector(x: 1, y: 0, z: 0), vector2: R3Vector(x: 0, y: 1, z: 0), expected: 1.4142135623730953),
                     Test(vector1: R3Vector(x: 1, y: 0, z: 0), vector2: R3Vector(x: 0, y: 1, z: 1), expected: 1.732050807568877),
                     Test(vector1: R3Vector(x: 1, y: 1, z: 1), vector2: R3Vector(x: -1, y: -1, z: -1), expected: 3.4641016151377544),
                     Test(vector1: R3Vector(x: 1, y: 2, z: 2), vector2: R3Vector(x: -0.3, y: 0.4, z: -1.2), expected: 3.8065732621348562)]

        for test in tests {
            let got = test.vector1.distance(to: test.vector2)

            let d = got - test.expected

            XCTAssertTrue(got ==~ test.expected, "with \(d): \(test.vector1) and  \(test.vector2)")
        }
    }

    func testOrthogonal() {
        let vectors = [R3Vector(x: 1, y: 0, z: 0),
                       R3Vector(x: 1, y: 1, z: 0),
                       R3Vector(x: 1, y: 2, z: 3),
                       R3Vector(x: 1, y: -2, z: -5),
                       R3Vector(x: 0.012, y: 0.0053, z: 0.00457)
        ]

        for vector in vectors {
            let orthogonal = vector.orthogonalized

            XCTAssertTrue(vector.dotProduct(with: orthogonal) ==~ 0.0, "\(vector) is not orthogonal to \(orthogonal)")
            XCTAssertTrue(orthogonal.normal ==~ 1.0, "\(vector) is not orthogonal to \(orthogonal.normal)")
        }
    }

    func testIdentities() {
        struct Test {
            let vector1: R3Vector
            let vector2: R3Vector
        }

        let tests = [Test(vector1: R3Vector(x: 0, y: 0, z: 0), vector2: R3Vector(x: 0, y: 0, z: 0)),
                     Test(vector1: R3Vector(x: 0, y: 0, z: 0), vector2: R3Vector(x: 0, y: 1, z: 2)),
                     Test(vector1: R3Vector(x: 1, y: 0, z: 0), vector2: R3Vector(x: 0, y: 2, z: 0)),
                     Test(vector1: R3Vector(x: 1, y: 0, z: 0), vector2: R3Vector(x: 0, y: 1, z: 1)),
                     Test(vector1: R3Vector(x: 1, y: 1, z: 1), vector2: R3Vector(x: -1, y: -1, z: -1)),
                     Test(vector1: R3Vector(x: 1, y: 2, z: 2), vector2: R3Vector(x: -0.3, y: 0.4, z: -1.2))]

        for test in tests {
            let cross1 = test.vector1.crossProduct(with: test.vector2)
            let cross2 = test.vector2.crossProduct(with: test.vector1)
            let dot1 = test.vector1.dotProduct(with: test.vector2)
            let dot2 = test.vector2.dotProduct(with: test.vector1)
            let angle1 = test.vector1.angle(with: test.vector2).radians
            let angle2 = test.vector2.angle(with: test.vector1).radians

            XCTAssertTrue(angle1 ==~ angle2, "with \(test.vector1) and \(test.vector2)")
            XCTAssertTrue(dot1 ==~ dot2, "with \(test.vector1) and \(test.vector2)")
            XCTAssertTrue((cross2 * -1) ==~ cross1, "with \(test.vector1) and \(test.vector2)")
        }
    }

    func testLargestAndSmallestComponents() {
        struct Test {
            let vector: R3Vector
            let largest: R3Axis
            let smallest: R3Axis
        }

        let tests = [Test(vector: R3Vector(x: 0, y: 0, z: 0), largest: .z, smallest: .z),
                     Test(vector: R3Vector(x: 1, y: 0, z: 0), largest: .x, smallest: .z),
                     Test(vector: R3Vector(x: 1, y: -1, z: 0), largest: .y, smallest: .z),
                     Test(vector: R3Vector(x: -1, y: -1.1, z: -1.1), largest: .z, smallest: .x),
                     Test(vector: R3Vector(x: 1, y: 2, z: 0), largest: .y, smallest: .z),
                     Test(vector: R3Vector(x: 0.5, y: -0.4, z: -0.5), largest: .z, smallest: .y),
                     Test(vector: R3Vector(x: 1e-15, y: 1e-14, z: 1e-13), largest: .z, smallest: .x)]

        for test in tests {
            XCTAssertEqual(test.vector.largestComponent, test.largest, "with \(test.vector)")
            XCTAssertEqual(test.vector.smallestComponent, test.smallest, "with \(test.vector)")
        }
    }

    func testComparisions() {
        struct Test {
            let vector1: R3Vector
            let vector2: R3Vector
            let bigger: Bool
            let equal: Bool
        }

        let tests = [Test(vector1: R3Vector(x: 0, y: 0, z: 0),
                          vector2: R3Vector(x: 0, y: 0, z: 0),
                          bigger: false, equal: true),
                     Test(vector1: R3Vector(x: 0, y: 0, z: 0),
                          vector2: R3Vector(x: 1, y: 0, z: 0),
                          bigger: false, equal: false),
                     Test(vector1: R3Vector(x: 0, y: 1, z: 0),
                          vector2: R3Vector(x: 0, y: 0, z: 0),
                          bigger: true, equal: false),
                     Test(vector1: R3Vector(x: 1, y: 2, z: 3),
                          vector2: R3Vector(x: 3, y: 2, z: 1),
                          bigger: false, equal: false),
                     Test(vector1: R3Vector(x: -1, y: 0, z: 0),
                          vector2: R3Vector(x: 0, y: 0, z: -1),
                          bigger: false, equal: false),
                     Test(vector1: R3Vector(x: 8, y: 6, z: 4),
                          vector2: R3Vector(x: 7, y: 5, z: 3),
                          bigger: true, equal: false),
                     Test(vector1: R3Vector(x: -1, y: -0.5, z: 0),
                          vector2: R3Vector(x: 0, y: 0, z: 0.1),
                          bigger: false, equal: false),
                     Test(vector1: R3Vector(x: 1, y: 2, z: 3),
                          vector2: R3Vector(x: 2, y: 3, z: 4),
                          bigger: false, equal: false),
                     Test(vector1: R3Vector(x: 1.23, y: 4.56, z: 7.89),
                          vector2: R3Vector(x: 1.23, y: 4.56, z: 7.89),
                          bigger: false, equal: true)]

        for test in tests {
            XCTAssertEqual(test.vector1 > test.vector2, test.bigger, "with \(test.vector1) and \(test.vector2)")
            XCTAssertEqual(test.vector1 >= test.vector2, test.bigger || test.equal, "with \(test.vector1) and \(test.vector2)")
            XCTAssertEqual(test.vector1 < test.vector2, !test.bigger && !test.equal, "with \(test.vector1) and \(test.vector2)")
            XCTAssertEqual(test.vector1 <= test.vector2, !test.bigger || test.equal, "with \(test.vector1) and \(test.vector2)")
        }
    }
}
