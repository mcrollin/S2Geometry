//
//  S1ChordAngleTests.swift
//  S2Geometry
//
//  Created by Marc Rollin on 4/17/17.
//  Copyright © 2017 Marc Rollin. All rights reserved.
//

import XCTest
@testable import S2Geometry

// swiftlint:disable nesting

class S1ChordAngleTests: XCTestCase {

    let zero: S1ChordAngle = 0
    let degree30 = S1ChordAngle.angle(S1Angle.degrees(30))
    let degree60 = S1ChordAngle.angle(S1Angle.degrees(60))
    let degree90 = S1ChordAngle.angle(S1Angle.degrees(90))
    let degree120 = S1ChordAngle.angle(S1Angle.degrees(120))
    let degree180: S1ChordAngle = .straight

    func testBasics() {
        struct Test {
            let a: S1ChordAngle
            let b: S1ChordAngle
            let lessThan: Bool
            let equal: Bool
        }

        let tests = [Test(a: .negative, b: .negative, lessThan: false, equal: true),
                     Test(a: .negative, b: zero, lessThan: true, equal: false),
                     Test(a: .negative, b: .straight, lessThan: true, equal: false),
                     Test(a: .negative, b: .infinite, lessThan: true, equal: false),

                     Test(a: zero, b: zero, lessThan: false, equal: true),
                     Test(a: zero, b: .straight, lessThan: true, equal: false),
                     Test(a: zero, b: .infinite, lessThan: true, equal: false),

                     Test(a: .straight, b: .straight, lessThan: false, equal: true),
                     Test(a: .straight, b: .infinite, lessThan: true, equal: false),

                     Test(a: .infinite, b: .infinite, lessThan: false, equal: true),
                     Test(a: .infinite, b: .straight, lessThan: false, equal: false)]

        for test in tests {
            XCTAssertEqual(test.a < test.b, test.lessThan, "with \(test.a) and \(test.b)")
            XCTAssertEqual(test.a == test.b, test.equal, "with \(test.a) and \(test.b)")
        }
    }

    func testIsFunction() {
        struct Test {
            let angle: S1ChordAngle
            let isNegative: Bool
            let isZero: Bool
            let isInfinite: Bool
            let isSpecial: Bool
            let isValid: Bool
        }

        let tests = [Test(angle: zero, isNegative: false, isZero: true,
                          isInfinite: false, isSpecial: false, isValid: true),
                     Test(angle: .negative, isNegative: true, isZero: false,
                          isInfinite: false, isSpecial: true, isValid: true),
                     Test(angle: .straight, isNegative: false, isZero: false,
                          isInfinite: false, isSpecial: false, isValid: true),
                     Test(angle: .infinite, isNegative: false, isZero: false,
                          isInfinite: true, isSpecial: true, isValid: true)]

        for test in tests {
            XCTAssertEqual(test.angle < 0, test.isNegative, "with \(test.angle)")
            XCTAssertEqual(test.angle == 0, test.isZero, "with \(test.angle)")
            XCTAssertEqual(test.angle.isInfinite(), test.isInfinite, "with \(test.angle)")
            XCTAssertEqual(test.angle.isSpecial(), test.isSpecial, "with \(test.angle)")
            XCTAssertEqual(test.angle.isValid(), test.isValid, "with \(test.angle)")
        }
    }

    func testFromAngle() {
        for angle in [0, 1, -1, .pi] {
            XCTAssertEqual(S1ChordAngle.angle(angle).angle, angle, "with \(angle)")
        }

        XCTAssertEqual(S1ChordAngle.angle(.pi), .straight)
        XCTAssertEqual(S1ChordAngle.angle(.infinite).angle, S1ChordAngle.infinite)
    }

    func testArithmetic() {
        struct Test {
            let a: S1ChordAngle
            let b: S1ChordAngle
            let expected: S1ChordAngle
        }

        let addTests = [Test(a: zero, b: zero, expected: zero),
                        Test(a: degree60, b: zero, expected: degree60),
                        Test(a: zero, b: degree60, expected: degree60),
                        Test(a: degree30, b: degree60, expected: degree90),
                        Test(a: degree60, b: degree30, expected: degree90),
                        Test(a: degree180, b: zero, expected: degree180),
                        Test(a: degree60, b: degree30, expected: degree90),
                        Test(a: degree90, b: degree90, expected: degree180),
                        Test(a: degree120, b: degree90, expected: degree180),
                        Test(a: degree120, b: degree120, expected: degree180),
                        Test(a: degree30, b: degree180, expected: degree180),
                        Test(a: degree180, b: degree180, expected: degree180)]

        for test in addTests {
            XCTAssertTrue(test.a.add(test.b) ==~ test.expected, "with \(test.a) and \(test.b)")
        }

        let subTests = [Test(a: zero, b: zero, expected: zero),
                        Test(a: degree60, b: degree60, expected: zero),
                        Test(a: degree180, b: degree180, expected: zero),
                        Test(a: zero, b: degree60, expected: zero),
                        Test(a: degree30, b: degree90, expected: zero),
                        Test(a: degree90, b: degree30, expected: degree60),
                        Test(a: degree90, b: degree60, expected: degree30),
                        Test(a: degree180, b: zero, expected: degree180)]

        for test in subTests {
            XCTAssertTrue(test.a.substract(test.b) ==~ test.expected, "with \(test.a) and \(test.b)")
        }
    }

    func testTrigonometry() {
        let epsilon = 1e-14
        let iters = 40

        for iter in 0...iters {
            let radians = .pi * Double(iter) / Double(iters)
            let angle = S1ChordAngle.angle(radians)

            XCTAssertTrue(abs(sin(radians) - angle.sinus) <= epsilon, "with \(iter)")
            XCTAssertTrue(abs(cos(radians) - angle.cosinus) <= epsilon, "with \(iter)")

            // Since tan(x) is unbounded near pi/4, we map the result back to an
            // angle before comparing. The assertion is that the result is equal to
            // the tangent of a nearby angle.
            XCTAssertTrue(abs(atan(tan(radians)) - atan(angle.tangent)) <= epsilon, "with \(iter)")
        }

        let angle90 = S1ChordAngle.squareLength(2)
        let angle180 = S1ChordAngle.squareLength(4)

        XCTAssertTrue(1.0 ==~ angle90.sinus)
        XCTAssertTrue(0.0 ==~ angle90.cosinus)
        XCTAssertTrue(angle90.tangent.isInfinite())
        XCTAssertTrue(0.0 ==~ angle180.sinus)
        XCTAssertTrue(-1.0 ==~ angle180.cosinus)
        XCTAssertTrue(0.0 ==~ angle180.tangent)
    }

    func testExpanded() {
        struct Test {
            let angle: S1ChordAngle
            let add: Double
            let expected: S1ChordAngle
        }

        let tests = [Test(angle: .infinite, add: -5, expected: .infinite),
                     Test(angle: .straight, add: 5, expected: S1ChordAngle.angle(4)),
                     Test(angle: S1ChordAngle.squareLength(42), add: 5, expected: S1ChordAngle.angle(4)),
                     Test(angle: zero, add: -5, expected: zero),
                     Test(angle: S1ChordAngle.squareLength(1.25), add: 0.25,
                          expected: S1ChordAngle.squareLength(1.5)),
                     Test(angle: S1ChordAngle.squareLength(0.75), add: 0.25,
                          expected: S1ChordAngle.squareLength(1))]

        for test in tests {
            XCTAssertEqual(test.angle.expanded(errorBound: test.add),
                           test.expected, "with \(test.angle) and \(test.add)")
        }

        XCTAssertTrue(zero.expanded(errorBound: zero.maxAngleError) ==~ zero)
        XCTAssertTrue(zero.expanded(errorBound: zero.maxPointError) ==~ zero)
    }
}
