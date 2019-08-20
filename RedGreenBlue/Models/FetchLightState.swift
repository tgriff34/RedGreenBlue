//
//  FetchLightState.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 8/17/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import Foundation
import SwiftyHue

struct FetchLightState {
    static func ofGroup(withLights: [String: Light], withGroupLightIdentifiers: [String]) -> [LightState]? {
        var result: [LightState] = []
        for lightIdentifier in withGroupLightIdentifiers {
            guard let lightState = withLights[lightIdentifier]?.state else {
                print("Error returning FetchLightState.ofGroup(withLights: withGroupLightIdentifiers:)")
                return nil
            }
            result.append(lightState)
        }

        return result
    }
}
