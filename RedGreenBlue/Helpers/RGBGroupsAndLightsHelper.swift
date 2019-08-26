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
        groupIdentifiers.sort(by: { Double($0)! < Double($1)! })
        return groupIdentifiers
    }
    static func retrieveLightIds(from lights: [String: Light]) -> [String] {
        var lightIdentifiers: [String] = []
        for light in lights {
            lightIdentifiers.append(light.key)
        }
        lightIdentifiers.sort(by: { Double($0)! < Double($1)! })
        return lightIdentifiers
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
    static func getAverageBrightnessOfLightsInGroup(_ lightIds: [String], _ allLights: [String: Light]) -> Int {
        var averageBrightnessOfLightsOn: Int = 0
        for identifier in lightIds {
            guard let state = allLights[identifier]?.state else {
                print("Error getting state of all lights")
                return 0
            }
            if state.on! == true {
                averageBrightnessOfLightsOn += state.brightness!
            }
        }
        return averageBrightnessOfLightsOn
    }
    static func getNumberOfLightsOnInGroup(_ lightIds: [String], _ allLights: [String: Light]) -> Int {
        var numberOfLightsOn: Int = 0
        for identifier in lightIds {
            guard let state = allLights[identifier]?.state else {
                print("Error getting state of all lights")
                return 0
            }
            if state.on! == true {
                numberOfLightsOn += 1
            }
        }
        return numberOfLightsOn
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
