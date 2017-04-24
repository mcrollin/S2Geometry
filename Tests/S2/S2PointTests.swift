//
//  S2PointTests.swift
//  S2Geometry
//
//  Created by Marc Rollin on 4/18/17.
//  Copyright © 2017 Marc Rollin. All rights reserved.
//

// swiftlint:disable identifier_name

@testable import S2Geometry
import XCTest

/// - todo: Missing test
///     - testRegularPoints
class S2PointTests: XCTestCase {

    let pz = S2Point(x: 0, y: 0, z: 1)
    let p000 = S2Point(x: 1, y: 0, z: 0)
    let p045 = S2Point(x: 1, y: 1, z: 0)
    let p090 = S2Point(x: 0, y: 1, z: 0)
    let p180 = S2Point(x: -1, y: 0, z: 0)

    // Degenerate triangles.
    let pr = S2Point(x: 0.257, y: -0.5723, z: 0.112)
    let pq = S2Point(x: -0.747, y: 0.401, z: 0.2235)

    // For testing the Girard area fall through case.
    let g1 = S2Point(x: 1, y: 1, z: 1)
    var g2: S2Point { return (g1 + pr * 1e-15).normalized }
    var g3: S2Point { return (g1 + 1e-15 * pq).normalized }

    func testOriginPoint() {
        let origin = S2Point.origin

        XCTAssertLessThan(abs(origin.normal - 1), Double.epsilon)

        // The point chosen below is about 66km from the north pole towards the East
        // Siberian Sea. The purpose of the `stToUV(2 / 3)` calculation is to keep the
        // origin as far away as possible from the longitudinal edges of large
        // Cells. (The line of longitude through the chosen point is always 1/3
        // or 2/3 of the way across any Cell with longitudinal edges that it
        // passes through.)
        let quadraticUV = S2Projection.quadratic.uv(st: 2.0 / 3)
        let point = S2Point(x: -0.01, y: 0.01 * quadraticUV, z: 1)

        XCTAssert(origin ==~ point, "Origin point should fall in the Siberian Sea.")

        // Check that the origin is not too close to either pole.
        // The Earth's mean radius in kilometers (according to NASA).
        let earthRadiusKm = 6371.01
        XCTAssertGreaterThan(acos(origin.z) * earthRadiusKm, 50)
    }

    func testPointCrossProduct() {
        typealias Test = (p1: S2Point, p2: S2Point, normal: Double)

        let tests = [
            Test(p1: p000, p2: p000, normal: 1),
            Test(p1: p000, p2: p090, normal: 2),
            Test(p1: p090, p2: p000, normal: 2),
            Test(p1: S2Point(x: 1, y: 2, z: 3), p2: S2Point(x: -4, y: 5, z: -6), normal: 2 * sqrt(934))
        ]

        for test in tests {
            let got = test.p1.pointCrossProduct(with: test.p2)

            XCTAssertEqual(got.normal, test.normal, "with \(test.p1) and \(test.p2)")
            XCTAssertEqual(got.dotProduct(with: test.p1), 0, "with \(test.p1) and \(test.p2)")
            XCTAssertEqual(got.dotProduct(with: test.p2), 0, "with \(test.p1) and \(test.p2)")
        }
    }

    func testDistance() {
        typealias Test = (p1: S2Point, p2: S2Point, distance: Double)

        let tests = [
            Test(p1: p000, p2: p000, distance: 0),
            Test(p1: p000, p2: p090, distance: .pi / 2),
            Test(p1: p000, p2: S2Point(x: 0, y: 1, z: 1), distance: .pi / 2),
            Test(p1: p000, p2: p180, distance: .pi),
            Test(p1: S2Point(x: 1, y: 2, z: 3),
                 p2: S2Point(x: 2, y: 3, z: -1),
                 distance: 1.2055891055045298)
        ]

        for test in tests {
            XCTAssertEqual(test.p1.distance(with: test.p2).radians, test.distance, "with \(test.p1) and \(test.p2)")
            XCTAssertEqual(test.p2.distance(with: test.p1).radians, test.distance, "with \(test.p1) and \(test.p2)")
        }
    }

    func testAlmostEqual() {
        typealias Test = (p1: S2Point, p2: S2Point, expected: Bool)

        let tests = [
            Test(p1: p000, p2: p000, expected: true),
            Test(p1: p000, p2: p090, expected: false),
            Test(p1: p000, p2: S2Point(x: 0, y: 1, z: 1), expected: false),
            Test(p1: p000, p2: p180, expected: false),
            Test(p1: S2Point(x: 1, y: 2, z: 3), p2: S2Point(x: 2, y: 3, z: -1), expected: false),
            Test(p1: p000, p2: S2Point(x: 1 + .epsilon, y: 0, z: 0), expected: true),
            Test(p1: p000, p2: S2Point(x: 1 - .epsilon, y: 0, z: 0), expected: true),
            Test(p1: p000, p2: S2Point(x: 1, y: .epsilon, z: 0), expected: true),
            Test(p1: p000, p2: S2Point(x: 1, y: .epsilon, z: .epsilon), expected: false),
            Test(p1: S2Point(x: 1, y: .epsilon, z: 0),
                 p2: S2Point(x: 1, y: -.epsilon, z: .epsilon), expected: false)
        ]

        for test in tests {
            XCTAssertEqual(test.p1 ==~ test.p2, test.expected, "with \(test.p1)) and \(test.p2)")
        }
    }

    func testArea() {
        typealias Test = (a: S2Point, b: S2Point, c: S2Point, expected: Double, nearness: Double)

        var tests = [
            Test(a: p000, b: p090, c: pz, expected: .pi / 2, nearness: 0),
            Test(a: p045, b: pz, c: p180, expected: 3 * .pi / 4, nearness: 0)
        ]

        // Make sure that Area has good *relative* accuracy even for very small areas.
        tests.append(Test(a: S2Point(x: .epsilon, y: 0, z: 1), b: S2Point(x: 0, y: .epsilon, z: 1),
                          c: pz, expected: 0.5 * .epsilon * .epsilon, nearness: .epsilon))

        // Make sure that it can handle degenerate triangles.
        tests.append(contentsOf: [
            Test(a: pr, b: pr, c: pr, expected: 0, nearness: 0),
            Test(a: pr, b: pq, c: pr, expected: 0, nearness: 0),
            Test(a: p000, b: p045, c: p090, expected: 0, nearness: 0)
        ])

        // Try a very long and skinny triangle.
        tests.append(Test(a: p000, b: S2Point(x: 1, y: 1, z: .epsilon),
                          c: p090, expected: 5.8578643762690495119753e-11, nearness: 1e-9))

        // Test out the Girard area
        tests.append(Test(a: g1, b: g2, c: g3, expected: 0, nearness: .epsilon))

        for test in tests {
            let delta = abs(S2Point.area(a: test.a, b: test.b, c: test.c) - test.expected)

            XCTAssertLessThanOrEqual(delta, test.nearness, "with \(test.a), \(test.b) and \(test.c)")
        }
    }

    func testAreaQuarterHemisphere() {
        typealias Test = (a: S2Point, b: S2Point, c: S2Point, d: S2Point, e: S2Point, expected: Double)

        var tests = [Test]()

        // Triangles with near-180 degree edges that sum to a quarter-sphere.
        tests.append(Test(a: S2Point(x: 1, y: 0.1 * .epsilon, z: .epsilon), b: p000, c: p045,
                          d: p180, e: pz, expected: .pi - 2 * .epsilon))

        // Four other triangles that sum to a quarter-sphere.
        tests.append(Test(a: S2Point(x: 1, y: 1, z: .epsilon), b: p000, c: p045,
                          d: p180, e: pz, expected: .pi))

        for test in tests {
            let area = S2Point.area(a: test.a, b: test.b, c: test.c)
                + S2Point.area(a: test.a, b: test.c, c: test.d)
                + S2Point.area(a: test.a, b: test.d, c: test.e)
                + S2Point.area(a: test.a, b: test.e, c: test.b)

            XCTAssertEqual(area, test.expected, "with \(test.a), \(test.b), \(test.c), \(test.d) and \(test.e)")
        }
    }

    func testPlanarCentroid() {
        typealias Test = (name: String, p0: S2Point, p1: S2Point, p2: S2Point, expected: S2Point)

        let tests = [
            Test(name: "xyz axis", p0: S2Point(x: 0, y: 0, z: 1), p1: S2Point(x: 0, y: 1, z: 0),
                 p2: S2Point(x: 1, y: 0, z: 0), expected: S2Point(x: 1.0 / 3, y: 1.0 / 3, z: 1.0 / 3)),
            Test(name: "same points", p0: S2Point(x: 1, y: 0, z: 0), p1: S2Point(x: 1, y: 0, z: 0),
                 p2: S2Point(x: 1, y: 0, z: 0), expected: S2Point(x: 1, y: 0, z: 0))
        ]

        for test in tests {
            let centroid = S2Point.planarCentroid(a: test.p0, b: test.p1, c: test.p2)

            XCTAssertEqual(centroid, test.expected, "with \(test.p0), \(test.p1) and \(test.p2)")
        }
    }

    func testTrueCentroid() {
        // Test TrueCentroid with very small triangles. This test assumes that
        // the triangle is small enough so that it is nearly planar.
        // The centroid of a planar triangle is at the intersection of its
        // medians, which is two-thirds of the way along each median.

        for _ in 0 ..< 100 {
            let f = RandomHelper.frame()
            let p = f.column(0)
            let x = f.column(1)
            let y = f.column(2)
            let d = 1e-4 * pow(1e-4, RandomHelper.double())

            // Make a triangle with two equal sides.
            var p0 = (p - x * d).normalized
            var p1 = (p + x * d).normalized
            var p2 = (p + y * d * 3).normalized
            var expected = (p + y * d).normalized
            var got = S2Point.trueCentroid(a: p0, b: p1, c: p2).normalized

            XCTAssertLessThanOrEqual(got.distance(with: expected), 2e-8)

            // Make a triangle with a right angle.
            p0 = p
            p1 = (p + x * d * 3).normalized
            p2 = (p + y * d * 6).normalized
            expected = (p + (x + y * 2) * d).normalized
            got = S2Point.trueCentroid(a: p0, b: p1, c: p2).normalized

            XCTAssertLessThanOrEqual(got.distance(with: expected), 2e-8)
        }
    }

    func testRegion() {
        let p = S2Point(x: 1, y: 0, z: 0)
        let r = S2Point(x: 1, y: 0, z: 0)

        XCTAssert(r.contains(point: p))
        XCTAssert(r.contains(point: r))
        XCTAssertFalse(r.contains(point: S2Point(x: 1, y: 0, z: 1)))

        /// - todo: CapBound, RectBound, ContainsCell and IntersectsCell tests
    }

    func testBenchmarkArea() {
        measure {
            for _ in 0 ..< 100_000 {
                _ = S2Point.area(a: self.p000, b: self.p090, c: self.pz)
            }
        }
    }

    func testBenchmarkAreaGirardCase() {
        measure {
            for _ in 0 ..< 100_000 {
                _ = S2Point.area(a: self.g1, b: self.g2, c: self.g3)
            }
        }
    }
}
