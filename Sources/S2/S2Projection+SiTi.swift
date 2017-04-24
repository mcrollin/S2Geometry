//
//  S2ProjectionSiTi.swift
//  S2Geometry
//
//  Created by Marc Rollin on 5/1/17.
//  Copyright © 2017 Marc Rollin. All rights reserved.
//

import Foundation

typealias S2FaceSiTiLevel = (face: Int, si: UInt64, ti: UInt64, level: Int)

extension S2Projection {
    /// The maximum value of an si- or ti-coordinate.
    /// It is one shift more than maxSize.
    static let maxSiTi = UInt64(S2CellIdentifier.maxSize << 1)

    /// Converts an si- or ti-value to the corresponding s- or t-value.
    /// Value is capped at 1.0.
    func st(siTi: UInt64) -> Double {
        let maxSiTi = S2Projection.maxSiTi

        if siTi > maxSiTi {
            return 1.0
        }

        return Double(siTi) / Double(maxSiTi)
    }

    /// Converts the s- or t-value to the nearest si- or ti-coordinate.
    /// The result may be outside the range of valid (si,ti)-values.
    /// Value of 0.49999999999999994 (math.NextAfter(0.5, -1)), will be incorrectly rounded up.
    func siTi(st: Double) -> UInt64 {
        let maxSiTi = S2Projection.maxSiTi

        if st < 0 {
            return 0 &- UInt64(-st * Double(maxSiTi) + 0.5)
        }

        return UInt64(st * Double(maxSiTi) + 0.5)
    }

    /// Transforms the (si, ti) coordinates to a (not necessarily unit length) Point on the given face.
    func xyz(face: Int, si: UInt64, ti: UInt64) -> S2Point {
        assert(0 ..< S2CellIdentifier.facesCount ~= face)

        return xyz(face: face,
                   u: uv(st: st(siTi: si)),
                   v: uv(st: st(siTi: ti)))
    }

    /// Transforms the (not necessarily unit length) Point to (face, si, ti) coordinates and the level the point is at.
    func faceSiTi(xyz xyzCoordinate: XYZPositionable) -> S2FaceSiTiLevel {
        let maxLevel = S2CellIdentifier.maxLevel
        let maxSiTi = S2Projection.maxSiTi
        let (face, u, v) = faceUV(xyz: xyzCoordinate)

        let si = siTi(st: st(uv: u))
        let ti = siTi(st: st(uv: v))

        // If the levels corresponding to si, ti are not equal, then p is not a cell center.
        // The si,ti values of 0 and maxSiTi need to be handled specially because they
        // do not correspond to cell centers at any valid level; they are mapped to level -1
        // by the code at the end.
        let level = maxLevel - S2CellIdentifier.leastSignificantBitSetNonZero(si | maxSiTi)

        if level < 0 || level != maxLevel - S2CellIdentifier.leastSignificantBitSetNonZero(ti | maxSiTi) {
            return S2FaceSiTiLevel(face: face, si: si, ti: ti, level: -1)
        }

        // In infinite precision, this test could be changed to ST == SiTi. However,
        // due to rounding errors, uvToST(xyzToFaceUV(faceUVToXYZ(stToUV(...)))) is
        // not idempotent. On the other hand, the center is computed exactly the same
        // way p was originally computed (if it is indeed the center of a Cell);
        // the comparison can be exact.
        let point = S2Point(x: xyzCoordinate.x, y: xyzCoordinate.y, z: xyzCoordinate.z)

        if point == xyz(face: face, si: si, ti: ti).normalized {
            return S2FaceSiTiLevel(face: face, si: si, ti: ti, level: level)
        }

        return S2FaceSiTiLevel(face: face, si: si, ti: ti, level: -1)
    }
}
