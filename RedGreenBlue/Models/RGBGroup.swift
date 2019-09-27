//
//  RGBGroup.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 9/4/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import Foundation
import SwiftyHue

struct RGBGroup: Equatable {
    let name: String
    let identifier: String
    let lightIdentifiers: [String]
    let action: LightState
    let modelId: String
    let type: GroupType
    var lights: [Light]

    static func == (lhs: RGBGroup, rhs: RGBGroup) -> Bool {
        return lhs.name == rhs.name &&
            lhs.identifier == rhs.identifier &&
            lhs.lights.count == rhs.lights.count
    }
}
