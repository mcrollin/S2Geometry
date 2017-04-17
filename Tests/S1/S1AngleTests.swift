//
//  S1AngleTests.swift
//  S2Geometry
//
//  Created by Marc Rollin on 4/10/17.
//  Copyright © 2017 Marc Rollin. All rights reserved.
//

import XCTest
@testable import S2Geometry

// swiftlint:disable nesting line_length

class S1AngleTests: XCTestCase {

    func testPiRadiansExactlyDegrees() {
        XCTAssertEqual(S1Angle.radians(.pi), .pi, "invalid pi from radians to radians")
        XCTAssertEqual(S1Angle.radians(.pi).degrees, 180, "invalid pi from radians to degrees")
        XCTAssertEqual(S1Angle.degrees(180), .pi, "invalid pi from degrees to radians")
        XCTAssertEqual(S1Angle.degrees(180).degrees, 180, "invalid pi from degrees to degrees")
        XCTAssertEqual(S1Angle.radians(.pi / 2).degrees, 90, "invalid pi / 2 from radians to degrees")
        XCTAssertEqual(S1Angle.radians(-.pi / 2).degrees, -90, "invalid -pi / 2 from radians to degrees")
        XCTAssertEqual(S1Angle.degrees(-45), -.pi / 4, "invalid -45 from degrees to radians")
    }

    func testEpsilon() {
        // For unknown reasons the first test gives a variance in the 16th decimal place.
        XCTAssertTrue(S1Angle.degrees(-45) ==~ S1Angle.degrees(-4500000, epsilon: .e5), "-4500000 e6")
        XCTAssertEqual(S1Angle.degrees(-60), S1Angle.degrees(-60000000, epsilon: .e6), "-60000000 e6")
        XCTAssertEqual(S1Angle.degrees(75), S1Angle.degrees(750000000, epsilon: .e7), "750000000 e7")

        XCTAssertEqual(S1Angle.degrees(-172.56123).epsilon5, -17256123, "-172.56123 epsilon5")
        XCTAssertEqual(S1Angle.degrees(12.345678).epsilon6, 12345678, "-172.56123 epsilon6")
        XCTAssertEqual(S1Angle.degrees(-12.3456789).epsilon7, -123456789, "-12.3456789 epsilon7")

        // Rounding tests
        struct Test {
            let degrees: Double
            let expected: Int
        }

        let tests = [Test(degrees: 0.500000001, expected: 1),
                     Test(degrees: -0.500000001, expected: -1),
                     Test(degrees: 0.499999999, expected: 0),
                     Test(degrees: -0.499999999, expected: 0)]

        for test in tests {
            XCTAssertEqual(S1Angle.degrees(test.degrees, epsilon: .e5).epsilon5, test.expected, "with \(test.degrees) in e5")
            XCTAssertEqual(S1Angle.degrees(test.degrees, epsilon: .e6).epsilon6, test.expected, "with \(test.degrees) in e6")
            XCTAssertEqual(S1Angle.degrees(test.degrees, epsilon: .e7).epsilon7, test.expected, "with \(test.degrees) in e7")
        }
    }

    func testNormalizeCorrectlyCannonicalizesAngles() {
        struct Test {
            let degrees: Double
            let expects: Double
        }

        let tests = [Test(degrees: 360, expects: 0),
                     Test(degrees: -180, expects: 180),
                     Test(degrees: 180, expects: 180),
                     Test(degrees: 540, expects: 180),
                     Test(degrees: -270, expects: 90)]

        for test in tests {
            XCTAssertEqual(S1Angle.degrees(test.degrees).normalized.degrees, test.expects, "with \(test.degrees)")
        }
    }

    func testDegreesVsRadians() {
        // This test tests the exactness of specific values between degrees and radians.
        for k in -8...8 {
            let k = Double(k)
            let k45 = k * 45

            XCTAssertEqual(S1Angle.degrees(k45), S1Angle.radians(k * .pi / 4), "with \(k)")
            XCTAssertEqual(S1Angle.degrees(k45).degrees, k45, "with \(k)")
        }

        struct Test {
            let degrees: Double
            let radians: Double
        }

        let tests = [Test(degrees: 180, radians: 1),
                     Test(degrees: 60, radians: 3),
                     Test(degrees: 36, radians: 5),
                     Test(degrees: 20, radians: 9),
                     Test(degrees: 4, radians: 45)]

        for k in 0...30 {
            let n = Double(1 << k)

            for test in tests {
                XCTAssertEqual(S1Angle.degrees(test.degrees / n).radians, S1Angle.radians(.pi / (test.radians * n)), "with \(n)")
                XCTAssertEqual(S1Angle.degrees(test.degrees / n), S1Angle.radians(.pi / (test.radians * n)), "with \(n)")
            }
        }
    }

    func testConversion() {
        let radian = S1Angle.radians(.pi)
        let degress = S1Angle.degrees(180)

        XCTAssertEqual(degress.degrees, radian.degrees)
        XCTAssertEqual(degress.radians, radian.radians)
    }

    func testIsInfinite() {
        XCTAssertTrue(S1Angle.degrees(.infinity).isInifinite())
        XCTAssertTrue(S1Angle.infinite.isInifinite())
    }

    func testAbsolute() {
        struct Test {
            let angle: S1Angle
            let expected: Double
        }

        let tests = [Test(angle: S1Angle.radians(0), expected: 0),
                     Test(angle: S1Angle.radians(.pi / 2), expected: .pi / 2),
                     Test(angle: S1Angle.radians(-.pi / 2), expected: .pi / 2)]

        for test in tests {
            XCTAssertEqual(test.angle.absolute, test.expected, "with \(test.angle)")
        }
    }
}
