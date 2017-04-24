//
//  S2ProjectionTests.swift
//  S2Geometry
//
//  Created by Marc Rollin on 4/19/17.
//  Copyright © 2017 Marc Rollin. All rights reserved.
//

@testable import S2Geometry
import XCTest

class S2ProjectionTests: XCTestCase {
    let maxSiTi = S2Projection.maxSiTi
    let facesCount = S2CellIdentifier.facesCount
    let maxLevel = S2CellIdentifier.maxLevel
    let projection = S2Projection.optimal

    func testSiTiST() {
        // Int -> Double -> Int direction.
        for _ in 0 ..< 1000 {
            let si = RandomHelper.uint64(0, maxSiTi - 1)
            let got = projection.siTi(st: projection.st(siTi: si))

            XCTAssertEqual(si, got)
        }

        let siTi = projection.siTi(st: projection.st(siTi: maxSiTi + 1))

        XCTAssertEqual(maxSiTi, siTi)

        // Double -> Int -> Double direction.
        for _ in 0 ..< 1000 {
            let st = RandomHelper.double(0, 1)
            let got = projection.st(siTi: projection.siTi(st: st))

            XCTAssertLessThanOrEqual(abs(st - got), 1e-9)
        }

        let st = projection.st(siTi: projection.siTi(st: 2))

        XCTAssertEqual(1, st)

        let negative = projection.siTi(st: -1)

        XCTAssertEqual(18_446_744_071_562_067_968, negative)
    }

    func testSTUV() {
        typealias Test = (identity: Double, projection: S2Projection, expected: Double)

        let tests = [
            Test(identity: 2.0 / 3, projection: .linear, expected: 0.3333333333333333),
            Test(identity: 2.0 / 3, projection: .tangent, expected: 0.2679491924311227),
            Test(identity: 2.0 / 3, projection: .quadratic, expected: 0.2592592592592592),
            Test(identity: 1.0 / 3, projection: .quadratic, expected: -0.25925925925925936)
        ]

        for test in tests {
            let uv = test.projection.uv(st: test.identity)
            let st = test.projection.st(uv: uv)

            XCTAssert(uv ==~ test.expected, "with \(test.projection)")
            XCTAssert(st ==~ test.identity, "with \(test.projection)")
        }
    }

    func testXYZFaceSiTi() {
        for level in 0 ..< maxLevel {
            for _ in 0 ..< 1000 {
                let cellId = RandomHelper.cellIdentifier(level: level)
                let point = cellId.point
                let faceSiTi = projection.faceSiTi(xyz: point)
                let op = projection.xyz(face: faceSiTi.face, si: faceSiTi.si, ti: faceSiTi.ti)

                XCTAssert(point ==~ op, "with \(level) and \(point)")
            }
        }
    }

    func testUVNormals() {
        let step = 1.0 / 1024

        for face in 0 ..< facesCount {
            var x = -1.0

            while x <= 1 {
                let uNormal = projection.xyz(face: face, u: x, v: -1)
                    .crossProduct(with: projection.xyz(face: face, u: x, v: 1))
                    .vector.angle(with: projection.uNormal(face: face, u: x))
                let vNormal = projection.xyz(face: face, u: -1, v: x)
                    .crossProduct(with: projection.xyz(face: face, u: 1, v: x))
                    .vector.angle(with: projection.vNormal(face: face, v: x))

                XCTAssert(uNormal ==~ 0.0, "with \(face) and \(x)")
                XCTAssert(vNormal ==~ 0.0, "with \(face) and \(x)")

                x += step
            }
        }
    }

    func testFaceUVToXYZ() {
        var sum = R3Vector(x: 0, y: 0, z: 0)
        let swapMask = 0x01

        // Check that each face appears exactly once.
        for face in 0 ..< facesCount {
            let center = projection.xyz(face: face, u: 0, v: 0)
            let largestComponent = center.vector.largestComponent

            XCTAssert(center ==~ projection.unitNormal(face: face), "with \(face)")

            switch largestComponent {
            case .x:
                XCTAssertEqual(abs(center.x), 1, "with \(face)")
            case .y:
                XCTAssertEqual(abs(center.y), 1, "with \(face)")
            case .z:
                XCTAssertEqual(abs(center.z), 1, "with \(face)")
            }

            sum += center.absolute.vector

            // Check that each face has a right-handed coordinate system.
            let got = projection.uAxis(face: face)
                .crossProduct(with: projection.vAxis(face: face))
                .dotProduct(with: projection.unitNormal(face: face))

            XCTAssertEqual(got, 1, "with \(face)")

            // Check that the Hilbert curves on each face combine to form a continuous curve over the entire cube.
            // The Hilbert curve on each face starts at (-1,-1) and terminates at either (1,-1) (if axes not swapped)
            // or (-1,1) (if swapped).
            var sign: Double = 1

            if Int(face) & swapMask == 1 {
                sign = -1
            }

            XCTAssertEqual(projection.xyz(face: face, u: sign, v: -sign),
                           projection.xyz(face: (face + 1) % 6, u: -1, v: -1),
                           "with \(face)")
        }

        // Adding up the absolute value all all the face normals should equal 2 on each axis.
        XCTAssert(sum ==~ R3Vector(x: 2, y: 2, z: 2))
    }

    func testFaceXYZToUV() {
        typealias Test = (face: Int, point: S2Point, uv: S2UV?)
        let point = S2Point(x: 1.1, y: 1.2, z: 1.3)
        let invertedPoint = S2Point(x: -1.1, y: -1.2, z: -1.3)
        let tests = [
            Test(face: 0, point: point, uv: S2UV(u: 1 + (1.0 / 11), v: 1 + (2.0 / 11))),
            Test(face: 0, point: invertedPoint, uv: nil),
            Test(face: 1, point: point, uv: S2UV(u: -11.0 / 12, v: 1 + (1.0 / 12))),
            Test(face: 1, point: invertedPoint, uv: nil),
            Test(face: 2, point: point, uv: S2UV(u: -11.0 / 13, v: -12.0 / 13)),
            Test(face: 2, point: invertedPoint, uv: nil),
            Test(face: 3, point: point, uv: nil),
            Test(face: 3, point: invertedPoint, uv: S2UV(u: 1 + (2.0 / 11), v: 1 + (1.0 / 11))),
            Test(face: 4, point: point, uv: nil),
            Test(face: 4, point: invertedPoint, uv: S2UV(u: 1 + (1.0 / 12), v: -(11.0 / 12))),
            Test(face: 5, point: point, uv: nil),
            Test(face: 5, point: invertedPoint, uv: S2UV(u: -12.0 / 13, v: -11.0 / 13))
        ]

        for test in tests {
            let got = projection.uv(face: test.face, xyz: test.point)

            if let got = got, let uv = test.uv {
                XCTAssert(got.u ==~ uv.u, "with \(test.point), \(test.face)")
                XCTAssert(got.v ==~ uv.v, "with \(test.point), \(test.face)")
            } else {
                XCTAssertNil(got, "with \(test.point), \(test.face)")
                XCTAssertNil(test.uv, "with \(test.point), \(test.face)")
            }
        }
    }

    func testFaceXYZtoUVW() {
        let origin = S2Point(x: 0, y: 0, z: 0)
        let positiveX = S2Point(x: 1, y: 0, z: 0)
        let negativeX = S2Point(x: -1, y: 0, z: 0)
        let positiveY = S2Point(x: 0, y: 1, z: 0)
        let negativeY = S2Point(x: 0, y: -1, z: 0)
        let positiveZ = S2Point(x: 0, y: 0, z: 1)
        let negativeZ = S2Point(x: 0, y: 0, z: -1)

        for face in 0 ..< facesCount {
            XCTAssertEqual(projection.uvw(face: face, xyz: origin),
                           origin, "with \(face)")
            XCTAssertEqual(projection.uvw(face: face, xyz: projection.uAxis(face: face)),
                           positiveX, "with \(face)")
            XCTAssertEqual(projection.uvw(face: face, xyz: projection.uAxis(face: face) * -1),
                           negativeX, "with \(face)")
            XCTAssertEqual(projection.uvw(face: face, xyz: projection.vAxis(face: face)),
                           positiveY, "with \(face)")
            XCTAssertEqual(projection.uvw(face: face, xyz: projection.vAxis(face: face) * -1),
                           negativeY, "with \(face)")
            XCTAssertEqual(projection.uvw(face: face, xyz: projection.unitNormal(face: face)),
                           positiveZ, "with \(face)")
            XCTAssertEqual(projection.uvw(face: face, xyz: projection.unitNormal(face: face) * -1),
                           negativeZ, "with \(face)")
        }
    }

    func testUVWAxis() {
        for face in 0 ..< facesCount {
            // Check that the axes are consistent with faceUVtoXYZ.
            XCTAssertEqual(projection.xyz(face: face, u: 1, v: 0) - projection.xyz(face: face, u: 0, v: 0),
                           projection.uAxis(face: face), "with \(face)")
            XCTAssertEqual(projection.xyz(face: face, u: 0, v: 1) - projection.xyz(face: face, u: 0, v: 0),
                           projection.vAxis(face: face), "with \(face)")
            XCTAssertEqual(projection.xyz(face: face, u: 0, v: 0),
                           projection.unitNormal(face: face), "with \(face)")

            // Check that every face coordinate frame is right-handed.
            let got = projection.uAxis(face: face)
                .crossProduct(with: projection.vAxis(face: face))
                .dotProduct(with: projection.unitNormal(face: face))

            XCTAssertEqual(got, 1, "with \(face)")

            XCTAssertEqual(projection.uAxis(face: face), projection.uvwAxis(face: face, axis: 0), "with \(face)")
            XCTAssertEqual(projection.vAxis(face: face), projection.uvwAxis(face: face, axis: 1), "with \(face)")
            XCTAssertEqual(projection.unitNormal(face: face), projection.uvwAxis(face: face, axis: 2), "with \(face)")
        }
    }

    func testUVWFace() {
        for face in 0 ..< facesCount {
            // Check that uvwFace is consistent with uvwAxis.
            for axis in 0 ..< 3 {
                XCTAssertEqual(projection.face(xyz: projection.uvwAxis(face: face, axis: axis) * -1),
                               projection.uvwFace(face: face, axis: axis, direction: 0),
                               "with \(face) and \(axis)")
                XCTAssertEqual(projection.face(xyz: projection.uvwAxis(face: face, axis: axis)),
                               projection.uvwFace(face: face, axis: axis, direction: 1),
                               "with \(face) and \(axis)")
            }
        }
    }

    func testXYZToFaceSiTi() {
        for level in 0 ..< maxLevel {
            for _ in 0 ..< 1000 {
                let cellId = RandomHelper.cellIdentifier(level: level)
                let faceSiTi = projection.faceSiTi(xyz: cellId.point)

                XCTAssertEqual(faceSiTi.level, level, "with \(cellId)")

                let i = Int(faceSiTi.si / 2)
                let j = Int(faceSiTi.ti / 2)
                let gotId = S2CellIdentifier(face: faceSiTi.face, i: i, j: j).parent(at: level)

                XCTAssertEqual(gotId, cellId)

                // Test a point near the cell center but not equal to it.
                let movedPoint = cellId.point + S2Point(x: 1e-13, y: 1e-13, z: 1e-13)
                let movedFaceSiTi = projection.faceSiTi(xyz: movedPoint)

                XCTAssertEqual(movedFaceSiTi.level, -1)
                XCTAssertEqual(movedFaceSiTi.face, faceSiTi.face)
                XCTAssertEqual(movedFaceSiTi.si, faceSiTi.si)
                XCTAssertEqual(movedFaceSiTi.ti, faceSiTi.ti)

                // Finally, test some random (si,ti) values that may be at different levels,
                // or not at a valid level at all (for example, si == 0).
                let mask = .max << UInt32(maxLevel - level)
                let randomFace = RandomHelper.int(0, facesCount - 1)

                var randomSi = maxSiTi + 1
                var randomTi = maxSiTi + 1

                while randomSi > maxSiTi || randomTi > maxSiTi {
                    randomSi = UInt64(RandomHelper.uint32() & mask)
                    randomTi = UInt64(RandomHelper.uint32() & mask)
                }

                let randomPoint = projection.xyz(face: randomFace, si: randomSi, ti: randomTi)
                let randomFaceSiTi = projection.faceSiTi(xyz: randomPoint)

                // The chosen point is on the edge of a top-level face cell.
                if randomFaceSiTi.face != randomFace {
                    XCTAssertEqual(randomFaceSiTi.level, -1)
                    XCTAssert(randomFaceSiTi.si == 0 || randomFaceSiTi.si == maxSiTi
                        || randomFaceSiTi.ti == 0 || randomFaceSiTi.ti == maxSiTi)

                    continue
                }

                XCTAssertEqual(randomFaceSiTi.si, randomSi)
                XCTAssertEqual(randomFaceSiTi.ti, randomTi)

                if randomFaceSiTi.level >= 0 {
                    let i = Int(faceSiTi.si / 2)
                    let j = Int(faceSiTi.ti / 2)
                    let gotPoint = S2CellIdentifier(face: randomFaceSiTi.face, i: i, j: j)
                        .parent(at: randomFaceSiTi.level)
                        .point

                    XCTAssert(gotPoint ==~ randomPoint)
                }
            }
        }
    }
}
