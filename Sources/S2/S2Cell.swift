//
//  S2Cell.swift
//  S2Geometry
//
//  Created by Marc Rollin on 4/24/17.
//  Copyright © 2017 Marc Rollin. All rights reserved.
//

import Foundation

struct S2Cell {

    let identifier: Identifier
    //    let orientation: Int8
    //    let uv: R2Rectangle
}

extension S2Cell {

    var face: Int { return identifier.face }
    var token: String { return identifier.token }
    var level: Int { return identifier.level }
}
