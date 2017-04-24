//
//  S2CellLookupTable.swift
//  S2Geometry
//
//  Created by Marc Rollin on 4/28/17.
//  Copyright © 2017 Marc Rollin. All rights reserved.
//

// swiftlint:disable function_parameter_count

import Foundation

class S2CellLookupTable {
    static let shared = S2CellLookupTable()

    fileprivate let ijToPosition = [
        [0, 1, 3, 2], // canonical order
        [0, 3, 1, 2], // axes swapped
        [2, 3, 1, 0], // bits inverted
        [2, 1, 3, 0] // swapped & inverted
    ]

    fileprivate let positionToIJ = [
        [0, 1, 3, 2], // canonical order:    (0,0), (0,1), (1,1), (1,0)
        [0, 2, 3, 1], // axes swapped:       (0,0), (1,0), (1,1), (0,1)
        [3, 2, 0, 1], // bits inverted:      (1,1), (1,0), (0,0), (0,1)
        [3, 1, 0, 2] // swapped & inverted: (1,1), (0,1), (0,0), (1,0)
    ]

    fileprivate let lookupBits = 4
    fileprivate let swapMask = 0x01
    fileprivate let invertMask = 0x02

    fileprivate let positionToOrientation: [Int]

    fileprivate(set) var ijLookup: [Int]
    fileprivate(set) var positionLookup: [Int]

    private func initializeTables(level: Int, i: Int, j: Int, position: Int,
                                  originOrientation: Int, orientation: Int) {
        guard level != lookupBits else {
            let ijIndex = ((i << lookupBits) + j) << 2
            let positionIndex = position << 2

            positionLookup[ijIndex + originOrientation] = positionIndex + orientation
            ijLookup[positionIndex + originOrientation] = ijIndex + orientation

            return
        }

        let (level, i, j, position) = (level + 1, i << 1, j << 1, position << 2)
        let r = positionToIJ[orientation]

        initializeTables(level: level, i: i + (r[0] >> 1), j: j + (r[0] & 1), position: position,
                         originOrientation: originOrientation, orientation: orientation ^ positionToOrientation[0])
        initializeTables(level: level, i: i + (r[1] >> 1), j: j + (r[1] & 1), position: position + 1,
                         originOrientation: originOrientation, orientation: orientation ^ positionToOrientation[1])
        initializeTables(level: level, i: i + (r[2] >> 1), j: j + (r[2] & 1), position: position + 2,
                         originOrientation: originOrientation, orientation: orientation ^ positionToOrientation[2])
        initializeTables(level: level, i: i + (r[3] >> 1), j: j + (r[3] & 1), position: position + 3,
                         originOrientation: originOrientation, orientation: orientation ^ positionToOrientation[3])
    }

    private init() {
        let length = 1 << (2 * lookupBits + 2)

        ijLookup = [Int](repeating: 0, count: length)
        positionLookup = ijLookup
        positionToOrientation = [swapMask, 0, 0, invertMask | swapMask]

        initializeTables(level: 0, i: 0, j: 0, position: 0,
                         originOrientation: 0, orientation: 0)
        initializeTables(level: 0, i: 0, j: 0, position: 0,
                         originOrientation: swapMask, orientation: swapMask)
        initializeTables(level: 0, i: 0, j: 0, position: 0,
                         originOrientation: invertMask, orientation: invertMask)
        initializeTables(level: 0, i: 0, j: 0, position: 0,
                         originOrientation: swapMask | invertMask, orientation: swapMask | invertMask)
    }
}
