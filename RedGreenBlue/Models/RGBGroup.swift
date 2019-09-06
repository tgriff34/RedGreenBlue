//
//  RGBGroup.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 9/4/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import Foundation
import SwiftyHue

struct RGBGroup {
    let name: String
    let identifier: String
    let lightIdentifiers: [String]
    let action: LightState
    let modelId: String
    let type: GroupType
    var lights: [Light]
}
