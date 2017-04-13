//
//  R3Vector+Angle.swift
//  S2Geometry
//
//  Created by Marc Rollin on 4/13/17.
//  Copyright © 2017 Marc Rollin. All rights reserved.
//

import Foundation

extension R3Vector {

    // Returns the angle with the other vector.
    func angle(with other: R3Vector) -> S1Angle {
        return S1Angle(radians: atan2(crossProduct(with: other).normal,
                                      dotProduct(with: other)))
    }
}
