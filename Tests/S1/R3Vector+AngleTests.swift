//
//  R3Vector+AngleTests.swift
//  S2Geometry
//
//  Created by Marc Rollin on 4/15/17.
//  Copyright © 2017 Marc Rollin. All rights reserved.
//

import XCTest
@testable import S2Geometry

// swiftlint:disable nesting line_length

class R3VectorsAngleTests: XCTestCase {

    func testAngle() {
        struct Test {
            let vector1: R3Vector
            let vector2: R3Vector
            let expected: Double
        }

        let tests = [
            Test(vector1: R3Vector(x: 1, y: 0, z: 0), vector2: R3Vector(x: 1, y: 0, z: 0), expected: 0),
            Test(vector1: R3Vector(x: 1, y: 0, z: 0), vector2: R3Vector(x: 0, y: 1, z: 0), expected: .pi / 2),
            Test(vector1: R3Vector(x: 1, y: 0, z: 0), vector2: R3Vector(x: 0, y: 1, z: 1), expected: .pi / 2),
            Test(vector1: R3Vector(x: 1, y: 0, z: 0), vector2: R3Vector(x: -1, y: 0, z: 0), expected: .pi),
            Test(vector1: R3Vector(x: 1, y: 2, z: 3), vector2: R3Vector(x: 2, y: 3, z: -1), expected: 1.2055891055045298)
        ]

        for test in tests {
            XCTAssertTrue(test.vector1.angle(with: test.vector2).radians ==~ test.expected, "with \(test.vector1) and \(test.vector2)")
            XCTAssertTrue(test.vector2.angle(with: test.vector1).radians ==~ test.expected, "with \(test.vector1) and \(test.vector2)")
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
            let angle1 = test.vector1.angle(with: test.vector2).radians
            let angle2 = test.vector2.angle(with: test.vector1).radians

            XCTAssertTrue(angle1 ==~ angle2, "with \(test.vector1) and \(test.vector2)")
        }
    }
}
