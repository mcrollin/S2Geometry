//
//  S2CellIdentifierTests.swift
//  S2Geometry
//
//  Created by Marc Rollin on 4/24/17.
//  Copyright © 2017 Marc Rollin. All rights reserved.
//

// swiftlint:disable type_body_length function_body_length file_length

@testable import S2Geometry
import XCTest

class S2CellIdentifierTests: XCTestCase {
    let facesCount = S2CellIdentifier.facesCount

    func testStringConversion() {
        XCTAssertEqual(S2CellIdentifier(value: 0x0).description, "Invalid: 0")
        XCTAssertEqual(S2CellIdentifier(value: 0x5000_0000_0000_0000).description, "2/")
        XCTAssertEqual(S2CellIdentifier(value: 0x6000_0000_1234_5700).description, "3/00000000000000002101220223")
        XCTAssertEqual(S2CellIdentifier(value: 0xBB04_0000_0000_0000).description, "5/31200")
    }

    func testFacePositionLevel() {
        for face in 0 ..< facesCount {
            let fpl = S2CellIdentifier(face: face, position: 0, level: 0)
            let f = S2CellIdentifier(face: face)

            XCTAssertEqual(fpl, f)
            XCTAssertEqual(fpl.face, f.face)
            XCTAssertEqual(fpl.face, face)
            XCTAssertEqual(fpl.token, f.token)
            XCTAssertEqual(fpl.description, f.description)
            XCTAssertEqual(fpl.level, f.level)
            XCTAssertEqual(fpl.level, 0)
        }
    }

    func testParentChildRelationships() {
        let cellId = S2CellIdentifier(face: 3, position: 0x1234_5678, level: S2CellIdentifier.maxLevel - 4)

        XCTAssert(cellId.isValid)
        XCTAssertEqual(cellId.face, 3)
        XCTAssertEqual(cellId.position, 0x1234_5700)
        XCTAssertEqual(cellId.level, 26) // 26 is maxLevel - 4
        XCTAssertFalse(cellId.isLeaf)
        XCTAssertFalse(cellId.isFace)

        XCTAssertEqual(cellId.childBegin(at: cellId.level + 2).position, 0x1234_5610)
        XCTAssertEqual(cellId.childBegin.position, 0x1234_5640)
        XCTAssertEqual(cellId.children[0].position, 0x1234_5640)
        XCTAssertEqual(cellId.parent.position, 0x1234_5400)
        XCTAssertEqual(cellId.parent(at: cellId.level - 2).position, 0x1234_5000)

        XCTAssertLessThan(cellId.childBegin.value, cellId.value)
        XCTAssertGreaterThan(cellId.childEnd.value, cellId.value)

        XCTAssertEqual(cellId.childEnd, cellId.childBegin.next.next.next.next)
        XCTAssertEqual(cellId.rangeMinimum, cellId.childBegin(at: S2CellIdentifier.maxLevel))
        XCTAssertEqual(cellId.rangeMaximum.next, cellId.childEnd(at: S2CellIdentifier.maxLevel))
    }

    func testContainment() {
        typealias Test = (x: S2CellIdentifier, y: S2CellIdentifier, containsY: Bool, containsX: Bool, intersectsY: Bool)

        let a: S2CellIdentifier = 0x8085_5C00_0000_0000 // Pittsburg
        let b: S2CellIdentifier = 0x8085_5D00_0000_0000 // child of a
        let c: S2CellIdentifier = 0x8085_5DC0_0000_0000 // child of b
        let d: S2CellIdentifier = 0x8085_6300_0000_0000 // part of Pittsburg disjoint from a

        let tests = [
            Test(x: a, y: a, containsY: true, containsX: true, intersectsY: true),
            Test(x: a, y: b, containsY: true, containsX: false, intersectsY: true),
            Test(x: a, y: c, containsY: true, containsX: false, intersectsY: true),
            Test(x: a, y: d, containsY: false, containsX: false, intersectsY: false),
            Test(x: b, y: b, containsY: true, containsX: true, intersectsY: true),
            Test(x: b, y: c, containsY: true, containsX: false, intersectsY: true),
            Test(x: b, y: d, containsY: false, containsX: false, intersectsY: false),
            Test(x: c, y: c, containsY: true, containsX: true, intersectsY: true),
            Test(x: c, y: d, containsY: false, containsX: false, intersectsY: false),
            Test(x: d, y: d, containsY: true, containsX: true, intersectsY: true)
        ]

        for test in tests {
            XCTAssertEqual(test.x.contains(identifier: test.y), test.containsY, "with \(test.x) and \(test.y)")
            XCTAssertEqual(test.y.contains(identifier: test.x), test.containsX, "with \(test.x) and \(test.y)")
            XCTAssertEqual(test.x.intersects(identifier: test.y), test.intersectsY, "with \(test.x) and \(test.y)")
        }
    }

    func testLatitudeLongitude() {
        typealias Test = (cellId: S2CellIdentifier, latitude: Double, longitude: Double)

        let tests = [
            Test(cellId: 0x47A1_CBD5_9552_2B39, latitude: 49.703498679, longitude: 11.770681595),
            Test(cellId: 0x4652_5318_B63B_E0F9, latitude: 55.685376759, longitude: 12.588490937),
            Test(cellId: 0x52B3_0B71_698E_729D, latitude: 45.486546517, longitude: -93.449700022),
            Test(cellId: 0x46ED_8886_CFAD_DA85, latitude: 58.299984854, longitude: 23.049300056),
            Test(cellId: 0x3663_F18A_24CB_E857, latitude: 34.364439040, longitude: 108.330699969),
            Test(cellId: 0x10A_06C0_A948_CF5D, latitude: -30.694551352, longitude: -30.048758753),
            Test(cellId: 0x2B2B_FD07_6787_C5DF, latitude: -25.285264027, longitude: 133.823116966),
            Test(cellId: 0xB09D_FF88_2A78_09E1, latitude: -75.000000031, longitude: 0.000000133),
            Test(cellId: 0x94DA_A3D0_0000_0001, latitude: -24.694439215, longitude: -47.537363213),
            Test(cellId: 0x87A1_0000_0000_0001, latitude: 38.899730392, longitude: -99.901813021),
            Test(cellId: 0x4FC7_6D50_0000_0001, latitude: 81.647200334, longitude: -55.631712940),
            Test(cellId: 0x3B00_9555_5555_5555, latitude: 10.050986518, longitude: 78.293170610),
            Test(cellId: 0x1DCC_4699_9155_5555, latitude: -34.055420593, longitude: 18.551140038),
            Test(cellId: 0xB112_966A_AAAA_AAAB, latitude: -69.219262171, longitude: 49.670072392)
        ]

        for test in tests {
            let ll1 = S2LatitudeLongitude.fromDegrees(latitude: test.latitude, longitude: test.longitude)
            let ll2 = test.cellId.latitudeLongitude
            let distance = ll1.distance(with: ll2)

            XCTAssert(distance <= 1e-9.degrees) // ~0.1mm on earth.

            let cellId = S2CellIdentifier(latitudeLongitude: ll1)

            XCTAssertEqual(test.cellId, cellId)
        }
    }

    func testEdgeNeighbors() {
        // Check the edge neighbors of face 1.
        for (face, id) in zip([5, 3, 2, 0], S2CellIdentifier(face: 1, i: 0, j: 0).parent(at: 0).edgeNeighbors) {
            XCTAssert(id.isFace, "with \(id)")
            XCTAssertEqual(id.face, face, "with \(id)")
        }

        // Check the edge neighbors of the corner cells at all levels.
        // This case is trickier because it requires projecting onto adjacent faces.
        let maxIJ = S2CellIdentifier.maxSize - 1
        for level in 1 ... S2CellIdentifier.maxLevel {
            let id = S2CellIdentifier(face: 1, i: 0, j: 0).parent(at: level)

            // These neighbors were determined manually using the face and axis relationships.
            let sizeIJ = S2CellIdentifier.sizeIJ(at: level)

            let expected = [
                S2CellIdentifier(face: 5, i: maxIJ, j: maxIJ).parent(at: level),
                S2CellIdentifier(face: 1, i: sizeIJ, j: 0).parent(at: level),
                S2CellIdentifier(face: 1, i: 0, j: sizeIJ).parent(at: level),
                S2CellIdentifier(face: 0, i: maxIJ, j: 0).parent(at: level)
            ]

            for (expectedId, neighbor) in zip(expected, id.edgeNeighbors) {
                XCTAssertEqual(neighbor, expectedId, "with \(level) and \(id)")
            }
        }
    }

    func testVertexNeighbors() {
        // Check the vertex neighbors of the center of face 2 at level 5.
        let id = S2CellIdentifier(point: S2Point(x: 0, y: 0, z: 1))
        let neighbors = id.vertexNeighbors(at: 5)
        let sorted = neighbors.sorted()

        for (n, neighbor) in sorted.enumerated() {
            var (i, j) = (1 << 29, 1 << 29)

            if n < 2 {
                i -= 1
            }

            if n == 0 || n == 3 {
                j -= 1
            }

            let expected = S2CellIdentifier(face: 2, i: i, j: j).parent(at: 5)

            XCTAssertEqual(neighbor, expected, "with \(i)")
        }

        // Check the vertex neighbors of the corner of faces 0, 4, and 5.
        let id2 = S2CellIdentifier(face: 0, position: 0, level: S2CellIdentifier.maxLevel)
        let neighbors2 = id2.vertexNeighbors(at: 0)
        let sorted2 = neighbors2.sorted()

        XCTAssertEqual(sorted2.count, 3)
        XCTAssertEqual(sorted2[0], S2CellIdentifier(face: 0))
        XCTAssertEqual(sorted2[1], S2CellIdentifier(face: 4))
    }

    // dedupCellIDs returns the unique slice of CellIDs from the sorted input list.
    private func dedup(_ ids: [S2CellIdentifier]) -> [S2CellIdentifier] {
        var out = [S2CellIdentifier]()
        var previous: S2CellIdentifier?

        for id in ids {
            if id != previous {
                out.append(id)
            }
            previous = id
        }

        return out
    }

    func testAllNeighbors() {
        // Check that AllNeighbors produces results that are consistent
        // with VertexNeighbors for a bunch of random cells.

        for _ in 0 ..< 100 {
            var id = RandomHelper.cellIdentifier()

            if id.isLeaf {
                id = id.parent
            }

            // testAllNeighbors computes approximately 2**(2*(diff+1)) cell ids,
            // so it's not reasonable to use large values of diff.
            let maxDiff = min(6, S2CellIdentifier.maxLevel - id.level - 1)
            let level = id.level + RandomHelper.int(0, maxDiff)

            // We compute AllNeighbors, and then add in all the children of id
            // at the given level. We then compare this against the result of finding
            // all the vertex neighbors of all the vertices of children of id at the
            // given level. These should give the same result.
            var expected = [S2CellIdentifier]()
            var all = id.allNeighbors(at: level)

            let end = id.childEnd(at: level + 1)
            var c = id.childBegin(at: level + 1)

            while c != end {
                all.append(c.parent)
                expected.append(contentsOf: c.vertexNeighbors(at: level))

                c = c.next
            }

            all = all.sorted()
            expected = expected.sorted()

            all = dedup(all)
            expected = dedup(expected)

            XCTAssertEqual(all, expected, "with \(level) and \(id)")
        }
    }

    func testToken() {
        typealias Test = (token: String, id: S2CellIdentifier)

        let tests = [
            Test(token: "X", id: 0x0),
            Test(token: "1", id: 0x1000_0000_0000_0000),
            Test(token: "3", id: 0x3000_0000_0000_0000),
            Test(token: "14", id: 0x1400_0000_0000_0000),
            Test(token: "41", id: 0x4100_0000_0000_0000),
            Test(token: "094", id: 0x0940_0000_0000_0000),
            Test(token: "537", id: 0x5370_0000_0000_0000),
            Test(token: "3fec", id: 0x3FEC_0000_0000_0000),
            Test(token: "72f3", id: 0x72F3_0000_0000_0000),
            Test(token: "52b8c", id: 0x52B8_C000_0000_0000),
            Test(token: "990ed", id: 0x990E_D000_0000_0000),
            Test(token: "4476dc", id: 0x4476_DC00_0000_0000),
            Test(token: "2a724f", id: 0x2A72_4F00_0000_0000),
            Test(token: "7d4afc4", id: 0x7D4A_FC40_0000_0000),
            Test(token: "b675785", id: 0xB675_7850_0000_0000),
            Test(token: "40cd6124", id: 0x40CD_6124_0000_0000),
            Test(token: "3ba32f81", id: 0x3BA3_2F81_0000_0000),
            Test(token: "08f569b5c", id: 0x08F5_69B5_C000_0000),
            Test(token: "385327157", id: 0x3853_2715_7000_0000),
            Test(token: "166c4d1954", id: 0x166C_4D19_5400_0000),
            Test(token: "96f48d8c39", id: 0x96F4_8D8C_3900_0000),
            Test(token: "0bca3c7f74c", id: 0x0BCA_3C7F_74C0_0000),
            Test(token: "1ae3619d12f", id: 0x1AE3_619D_12F0_0000),
            Test(token: "07a77802a3fc", id: 0x07A7_7802_A3FC_0000),
            Test(token: "4e7887ec1801", id: 0x4E78_87EC_1801_0000),
            Test(token: "4adad7ae74124", id: 0x4ADA_D7AE_7412_4000),
            Test(token: "90aba04afe0c5", id: 0x90AB_A04A_FE0C_5000),
            Test(token: "8ffc3f02af305c", id: 0x8FFC_3F02_AF30_5C00),
            Test(token: "6fa47550938183", id: 0x6FA4_7550_9381_8300),
            Test(token: "aa80a565df5e7fc", id: 0xAA80_A565_DF5E_7FC0),
            Test(token: "01614b5e968e121", id: 0x0161_4B5E_968E_1210),
            Test(token: "aa05238e7bd3ee7c", id: 0xAA05_238E_7BD3_EE7C),
            Test(token: "48a23db9c2963e5b", id: 0x48A2_3DB9_C296_3E5B)
        ]

        for test in tests {
            XCTAssertEqual(test.token, test.id.token)

            let cellId = S2Cell.Identifier(token: test.token)

            XCTAssertEqual(test.token, cellId.token)
        }
    }

    func testTokenErrors() {
        let tests = [
            "876b e99",
            "876bee99\n",
            "876[ee99",
            " 876bee99"
        ]

        for test in tests {
            let id = S2CellIdentifier(token: test)

            XCTAssertEqual(id.value, 0x0)
        }
    }

    func testIJLevelToBoundUV() {
        typealias Test = (i: Int, j: Int, level: Int, expected: R2Rectangle)
        let maxIJ = 1 << S2CellIdentifier.maxLevel - 1

        // The i/j space is [0, 2^30 - 1) which maps to [-1, 1] for the
        // x/y axes of the face surface. Results are scaled by the size of a cell
        // at the given level. At level 0, everything is one cell of the full size
        // of the space.  At maxLevel, the bounding rect is almost floating point
        // noise.

        // What should be out of bounds values, but passes the C++ code as well.
        var tests = [
            Test(i: -1, j: -1, level: 0, expected: R2Rectangle(points: R2Point(x: -5, y: -5), R2Point(x: -1, y: -1))),
            Test(i: -1 * maxIJ, j: -1 * maxIJ, level: 0,
                 expected: R2Rectangle(points: R2Point(x: -5, y: -5), R2Point(x: -1, y: -1))),
            Test(i: -1, j: -1, level: S2CellIdentifier.maxLevel,
                 expected: R2Rectangle(points: R2Point(x: -1.0000000024835267, y: -1.0000000024835267),
                                       R2Point(x: -1, y: -1))),
            Test(i: 0, j: 0, level: S2CellIdentifier.maxLevel + 1,
                 expected: R2Rectangle(points: R2Point(x: -1, y: -1), R2Point(x: -1, y: -1)))
        ]

        // Minimum i,j at different levels
        tests.append(contentsOf: [
            Test(i: 0, j: 0, level: 0, expected: R2Rectangle(points: R2Point(x: -1, y: -1), R2Point(x: 1, y: 1))),
            Test(i: 0, j: 0, level: S2CellIdentifier.maxLevel / 2,
                 expected: R2Rectangle(points: R2Point(x: -1, y: -1),
                                       R2Point(x: -0.999918621033430099, y: -0.999918621033430099))),
            Test(i: 0, j: 0, level: S2CellIdentifier.maxLevel,
                 expected: R2Rectangle(points: R2Point(x: -1, y: -1),
                                       R2Point(x: -0.999999997516473060, y: -0.999999997516473060)))
        ])

        // Just a hair off the outer bounds at different levels.
        tests.append(contentsOf: [
            Test(i: 1, j: 1, level: 0, expected: R2Rectangle(points: R2Point(x: -1, y: -1), R2Point(x: 1, y: 1))),
            Test(i: 1, j: 1, level: S2CellIdentifier.maxLevel / 2,
                 expected: R2Rectangle(points: R2Point(x: -1, y: -1),
                                       R2Point(x: -0.999918621033430099, y: -0.999918621033430099))),
            Test(i: 1, j: 1, level: S2CellIdentifier.maxLevel,
                 expected: R2Rectangle(points: R2Point(x: -0.9999999975164731, y: -0.9999999975164731),
                                       R2Point(x: -0.9999999950329462, y: -0.9999999950329462)))
        ])

        // Center point of the i,j space at different levels.
        tests.append(contentsOf: [
            Test(i: maxIJ / 2, j: maxIJ / 2, level: 0,
                 expected: R2Rectangle(points: R2Point(x: -1, y: -1), R2Point(x: 1, y: 1))),
            Test(i: maxIJ / 2, j: maxIJ / 2, level: S2CellIdentifier.maxLevel / 2,
                 expected: R2Rectangle(points: R2Point(x: -0.000040691345930099, y: -0.000040691345930099),
                                       R2Point(x: 0, y: 0))),
            Test(i: maxIJ / 2, j: maxIJ / 2, level: S2CellIdentifier.maxLevel,
                 expected: R2Rectangle(points: R2Point(x: -0.000000001241763433, y: -0.000000001241763433),
                                       R2Point(x: 0, y: 0)))
        ])

        // Maximum i, j at different levels.
        tests.append(contentsOf: [
            Test(i: maxIJ, j: maxIJ, level: 0,
                 expected: R2Rectangle(points: R2Point(x: -1, y: -1), R2Point(x: 1, y: 1))),
            Test(i: maxIJ, j: maxIJ, level: S2CellIdentifier.maxLevel / 2,
                 expected: R2Rectangle(points: R2Point(x: 0.999918621033430099, y: 0.999918621033430099),
                                       R2Point(x: 1, y: 1))),
            Test(i: maxIJ, j: maxIJ, level: S2CellIdentifier.maxLevel,
                 expected: R2Rectangle(points: R2Point(x: 0.999999997516473060, y: 0.999999997516473060),
                                       R2Point(x: 1, y: 1)))
        ])

        for test in tests {
            let uv = S2CellIdentifier.boundUV(i: test.i, j: test.j, level: test.level)

            XCTAssert(uv ==~ test.expected, "with \(test.i), \(test.j), \(test.level), \(uv) and \(test.expected)")
        }
    }

    func testCommonAncestorLevel() {
        typealias Test = (id: S2CellIdentifier, other: S2CellIdentifier, expected: Int?)

        // Identical cell IDs.
        var tests = [
            Test(id: S2CellIdentifier(face: 0),
                 other: S2CellIdentifier(face: 0),
                 expected: 0),
            Test(id: S2CellIdentifier(face: 0).childBegin(at: 30),
                 other: S2CellIdentifier(face: 0).childBegin(at: 30),
                 expected: 30)
        ]

        // One cell is a descendant of the other.
        tests.append(contentsOf: [
            Test(id: S2CellIdentifier(face: 0).childBegin(at: 30),
                 other: S2CellIdentifier(face: 0),
                 expected: 0),
            Test(id: S2CellIdentifier(face: 5),
                 other: S2CellIdentifier(face: 5).childEnd(at: 30).previous,
                 expected: 0)
        ])

        // No common ancestors.
        tests.append(contentsOf: [
            Test(id: S2CellIdentifier(face: 0),
                 other: S2CellIdentifier(face: 5),
                 expected: nil),
            Test(id: S2CellIdentifier(face: 2).childBegin(at: 30),
                 other: S2CellIdentifier(face: 3).childBegin(at: 20),
                 expected: nil)
        ])

        // Common ancestor distinct from both.
        tests.append(contentsOf: [
            Test(id: S2CellIdentifier(face: 5).childBegin(at: 9).next.childBegin(at: 15),
                 other: S2CellIdentifier(face: 5).childBegin(at: 9).childBegin(at: 20),
                 expected: 8),
            Test(id: S2CellIdentifier(face: 0).childBegin(at: 2).childBegin(at: 30),
                 other: S2CellIdentifier(face: 0).childBegin(at: 2).next.childBegin(at: 5),
                 expected: 1)
        ])

        for test in tests {
            XCTAssertEqual(test.id.commonAncestorLevel(identifier: test.other), test.expected)
            XCTAssertEqual(test.other.commonAncestorLevel(identifier: test.id), test.expected)
        }
    }

    func testDistanceToBegin() {
        typealias Test = (id: S2CellIdentifier, expected: Int64)
        let maxLevel = S2CellIdentifier.maxLevel

        // At level 0 (i.e. full faces), there are only 6 cells from
        // the last face to the beginning of the Hilbert curve.
        var tests = [
            Test(id: S2CellIdentifier(face: 5).childEnd(at: 0), expected: 6)
        ]

        // From the last cell on the last face at the smallest cell size,
        // there are the maximum number of possible cells.
        tests.append(Test(id: S2CellIdentifier(face: 5).childEnd(at: maxLevel),
                          expected: Int64(6 * (1 << UInt(2 * maxLevel)))))

        // From the first cell on the first face.
        tests.append(Test(id: S2CellIdentifier(face: 0).childBegin(at: 0), expected: 0))

        // From the first cell at the smallest level on the first face.
        tests.append(Test(id: S2CellIdentifier(face: 0).childBegin(at: maxLevel), expected: 0))

        for test in tests {
            XCTAssertEqual(test.id.distanceFromBegin, test.expected, "with \(test.id)")
        }

        // Test that advancing from the beginning by the distance from a cell gets us back to that cell.
        let id = S2CellIdentifier(face: 3, position: 0x1234_5678, level: maxLevel - 4)
        let expected = S2CellIdentifier(face: 0).childBegin(at: id.level).advance(id.distanceFromBegin)

        XCTAssertEqual(id, expected)
    }

    func testMostSignificantBitSetNonZero() {
        var testOne: UInt64 = 0x8000_0000_0000_0000
        var testAll: UInt64 = 0xFFFF_FFFF_FFFF_FFFF
        var testSome: UInt64 = 0xFEDC_BA98_7654_3210

        for i in stride(from: 63, to: -1, by: -1) {
            XCTAssertEqual(S2CellIdentifier.mostSignificantBitSetNonZero(testOne), i)
            XCTAssertEqual(S2CellIdentifier.mostSignificantBitSetNonZero(testAll), i)
            XCTAssertEqual(S2CellIdentifier.mostSignificantBitSetNonZero(testSome), i)

            testOne >>= 1
            testAll >>= 1
            testSome >>= 1
        }

        XCTAssertEqual(S2CellIdentifier.mostSignificantBitSetNonZero(1), 0)
        XCTAssertEqual(S2CellIdentifier.mostSignificantBitSetNonZero(0), 0)
    }

    func testLeastSignificantBitSetNonZero() {
        var testOne: UInt64 = 0x0000_0000_0000_0001
        var testAll: UInt64 = 0xFFFF_FFFF_FFFF_FFFF
        var testSome: UInt64 = 0x0123_4567_89AB_CDEF

        for i in 0 ... 63 {
            XCTAssertEqual(S2CellIdentifier.leastSignificantBitSetNonZero(testOne), i)
            XCTAssertEqual(S2CellIdentifier.leastSignificantBitSetNonZero(testAll), i)
            XCTAssertEqual(S2CellIdentifier.leastSignificantBitSetNonZero(testSome), i)

            testOne <<= 1
            testAll <<= 1
            testSome <<= 1
        }

        XCTAssertEqual(S2CellIdentifier.leastSignificantBitSetNonZero(1), 0)
        XCTAssertEqual(S2CellIdentifier.leastSignificantBitSetNonZero(0), 0)
    }

    func testWrapping() {
        typealias Test = (message: String, got: S2CellIdentifier, expected: S2CellIdentifier)
        let id = S2CellIdentifier(face: 3, position: 0x1234_5678, level: S2CellIdentifier.maxLevel - 4)
        let maxLevel = S2CellIdentifier.maxLevel
        let faceBits = S2CellIdentifier.faceBits

        let tests = [
            Test(message: "test wrap from beginning to end of Hilbert curve",
                 got: S2CellIdentifier(face: 5).childEnd(at: 0).previous,
                 expected: S2CellIdentifier(face: 0).childBegin(at: 0).previousWrap),
            Test(message: "smallest end leaf wraps to smallest first leaf using PrevWrap",
                 got: S2CellIdentifier(face: 5, position: UInt64.max >> faceBits, level: maxLevel),
                 expected: S2CellIdentifier(face: 0).childBegin(at: maxLevel).previousWrap),
            Test(message: "smallest end leaf wraps to smallest first leaf using advanceWrap",
                 got: S2CellIdentifier(face: 5, position: UInt64.max >> faceBits, level: maxLevel),
                 expected: S2CellIdentifier(face: 0).childBegin(at: maxLevel).advanceWrap(-1)),
            Test(message: "PrevWrap is the same as advanceWrap(-1)",
                 got: S2CellIdentifier(face: 0).childBegin(at: maxLevel).advanceWrap(-1),
                 expected: S2CellIdentifier(face: 0).childBegin(at: maxLevel).previousWrap),
            Test(message: "Prev + NextWrap stays the same at given level",
                 got: S2CellIdentifier(face: 0).childBegin(at: 4),
                 expected: S2CellIdentifier(face: 5).childEnd(at: 4).previous.nextWrap),
            Test(message: "advanceWrap forward and back stays the same at given level",
                 got: S2CellIdentifier(face: 0).childBegin(at: 4),
                 expected: S2CellIdentifier(face: 5).childEnd(at: 4).advance(-1).advanceWrap(1)),
            Test(message: "previous.nextWrap stays same for first cell at level",
                 got: S2CellIdentifier(face: 0, position: 0, level: maxLevel),
                 expected: S2CellIdentifier(face: 5).childEnd(at: maxLevel).previous.nextWrap),
            Test(message: "advanceWrap forward and back stays same for first cell at level",
                 got: S2CellIdentifier(face: 0, position: 0, level: maxLevel),
                 expected: S2CellIdentifier(face: 5).childEnd(at: maxLevel).advance(-1).advanceWrap(1)),
            Test(message: "advancing 7 steps around cube should end up one past start.",
                 got: S2CellIdentifier(face: 1),
                 expected: S2CellIdentifier(face: 0).childBegin(at: 0).advanceWrap(7)),
            Test(message: "twice around should end up where we started",
                 got: S2CellIdentifier(face: 0).childBegin(at: 0),
                 expected: S2CellIdentifier(face: 0).childBegin(at: 0).advanceWrap(12)),
            Test(message: "backwards once around plus one step should be one before we started",
                 got: S2CellIdentifier(face: 4),
                 expected: S2CellIdentifier(face: 5).advanceWrap(-7)),
            Test(message: "wrapping even multiple of times around should end where we started",
                 got: S2CellIdentifier(face: 0).childBegin(at: 0),
                 expected: S2CellIdentifier(face: 0).childBegin(at: 0).advanceWrap(-12_000_000)),
            Test(message: "wrapping combination of even times around should end where it started",
                 got: S2CellIdentifier(face: 0).childBegin(at: 5).advanceWrap(6644),
                 expected: S2CellIdentifier(face: 0).childBegin(at: 5).advanceWrap(-11788)),
            Test(message: "moving 256 should advance us one cell at max level",
                 got: id.next.childBegin(at: maxLevel),
                 expected: id.childBegin(at: maxLevel).advanceWrap(256)),
            Test(message: "wrapping by 4 times cells per face should advance 4 faces",
                 got: S2CellIdentifier(face: 1, position: 0, level: maxLevel),
                 expected: S2CellIdentifier(face: 5, position: 0, level: maxLevel)
                     .advanceWrap(Int64(2 << (2 * maxLevel))))
        ]

        for test in tests {
            XCTAssertEqual(test.got, test.expected, test.message)
        }
    }

    func testAdvance() {
        typealias Test = (id: S2CellIdentifier, steps: Int64, expected: S2CellIdentifier)
        let maxLevel = S2CellIdentifier.maxLevel

        let tests = [
            Test(id: S2CellIdentifier(face: 0).childBegin(at: 0),
                 steps: 7,
                 expected: S2CellIdentifier(face: 5).childEnd(at: 0)),
            Test(id: S2CellIdentifier(face: 0).childBegin(at: 0),
                 steps: 12,
                 expected: S2CellIdentifier(face: 5).childEnd(at: 0)),
            Test(id: S2CellIdentifier(face: 5).childEnd(at: 0),
                 steps: -7,
                 expected: S2CellIdentifier(face: 0).childBegin(at: 0)),
            Test(id: S2CellIdentifier(face: 5).childEnd(at: 0),
                 steps: -12_000_000,
                 expected: S2CellIdentifier(face: 0).childBegin(at: 0)),
            Test(id: S2CellIdentifier(face: 0).childBegin(at: 5),
                 steps: 500,
                 expected: S2CellIdentifier(face: 5).childEnd(at: 5).advance(500 - (6 << (2 * 5)))),
            Test(id: S2CellIdentifier(face: 3, position: 0x1234_5678, level: maxLevel - 4).childBegin(at: maxLevel),
                 steps: 256,
                 expected: S2CellIdentifier(face: 3, position: 0x1234_5678, level: maxLevel - 4)
                     .next.childBegin(at: maxLevel)),
            Test(id: S2CellIdentifier(face: 1, position: 0, level: maxLevel),
                 steps: Int64(4 << (2 * maxLevel)),
                 expected: S2CellIdentifier(face: 5, position: 0, level: maxLevel))
        ]

        for test in tests {
            XCTAssertEqual(test.id.advance(test.steps), test.expected)
        }
    }

    func testFaceSiTi() {
        let maxLevel = S2CellIdentifier.maxLevel
        let id = S2CellIdentifier(face: 3, position: 0x1234_5678, level: maxLevel)

        // Check that the (si, ti) coordinates of the center end in a
        // 1 followed by (30 - level) 0's.
        for level in 0 ... maxLevel {
            let l = maxLevel - level
            let expected = UInt64(1 << level)
            let mask = UInt64(1 << (level + 1) - 1)

            let (_, si, ti) = id.parent(at: l).faceSiTi

            XCTAssertEqual(si & mask, expected, "with \(level)")
            XCTAssertEqual(ti & mask, expected, "with \(level)")
        }
    }

    func testContinuity() {
        let projection = S2Projection.optimal
        let maxWalkLevel = 8
        let cellSize = 1.0 / Double(1 << maxWalkLevel)

        // Make sure that sequentially increasing cell ids form a continuous
        // path over the surface of the sphere, i.e. there are no
        // discontinuous jumps from one region to another.
        let maxDist = S2Metric.maxWidth.value(at: maxWalkLevel)
        let end = S2CellIdentifier(face: 5).childEnd(at: maxWalkLevel)
        var id = S2CellIdentifier(face: 0).childBegin(at: maxWalkLevel)

        while id != end {

            let got = id.rawPoint.vector.angle(with: id.nextWrap.rawPoint.vector)

            XCTAssertLessThan(got, maxDist, "with \(id)")
            XCTAssertEqual(id.nextWrap, id.advanceWrap(1), "with \(id)")
            XCTAssertEqual(id, id.nextWrap.advanceWrap(-1), "with \(id)")

            // Check that the rawPoint() returns the center of each cell
            // in (s,t) coordinates.
            let (_, u, v) = projection.faceUV(xyz: id.rawPoint)

            XCTAssert(remainder(projection.st(uv: u), 0.5 * cellSize) ==~ 0.0)
            XCTAssert(remainder(projection.st(uv: v), 0.5 * cellSize) ==~ 0.0)

            id = id.next
        }
    }
}
