//
//  String+PaddingLeft.swift
//  S2Geometry
//
//  Created by Marc Rollin on 4/25/17.
//  Copyright © 2017 Marc Rollin. All rights reserved.
//

import Foundation

extension String {

    func paddingLeft(toLength newLength: Int, withPad padCharacter: Character) -> String {
        let length = characters.count

        if length < newLength {
            return String(repeatElement(padCharacter, count: newLength - length)) + self
        }

        return self
    }
}
