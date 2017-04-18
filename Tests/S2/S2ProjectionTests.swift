//
//  S2ProjectionTests.swift
//  S2Geometry
//
//  Created by Marc Rollin on 4/19/17.
//  Copyright © 2017 Marc Rollin. All rights reserved.
//

import XCTest
@testable import S2Geometry

class S2ProjectionTests: XCTestCase {

    func testUnity() {
        typealias Test = (identity: Double, projection: S2Projection, expected: Double)

        let tests = [
            Test(identity: 2.0 / 3, projection: .linear, expected: 0.3333333333333333),
            Test(identity: 2.0 / 3, projection: .tangent, expected: 0.2679491924311227),
            Test(identity: 2.0 / 3, projection: .quadratic, expected: 0.2592592592592592),
            Test(identity: 1.0 / 3, projection: .quadratic, expected: -0.25925925925925936)
        ]

        for test in tests {
            let uv = test.projection.stToUV(test.identity)
            let st = test.projection.uvToST(uv)

            XCTAssert(uv ==~ test.expected, "with \(test.projection)")
            XCTAssert(st ==~ test.identity, "with \(test.projection)")
        }
    }
}
