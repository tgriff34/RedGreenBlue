//
//  RGBGroupsAndLightsHelper.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 8/20/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import Foundation
import SwiftyHue

class RGBGroupsAndLightsHelper {
    static func retrieveGroupIds(from groups: [String: Group]) -> [String] {
        var groupIdentifiers: [String] = []
        for group in groups {
            groupIdentifiers.append(group.key)
        }
        groupIdentifiers.sort()
        return groupIdentifiers
    }
    static func retrieveLightState(from sender: UISwitch) -> LightState {
        var lightState = LightState()
        if sender.isOn {
            lightState.on = true
        } else {
            lightState.on = false
        }
        return lightState
    }
    private static var previousTimer: Timer? = nil {
        willSet {
            previousTimer?.invalidate()
        }
    }
    static func sendTimeSensistiveAPIRequest(completion: @escaping () -> Void) {
        guard previousTimer == nil else { return }
        previousTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false, block: { _ in
            previousTimer = nil
            completion()
        })
    }
}
