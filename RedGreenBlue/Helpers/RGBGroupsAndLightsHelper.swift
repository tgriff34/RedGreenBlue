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
    static let shared = RGBGroupsAndLightsHelper()

    func setLightState(for group: RGBGroup, using swiftyHue: SwiftyHue,
                       with lightState: LightState, completion: @escaping () -> Void) {
        swiftyHue.bridgeSendAPI.setLightStateForGroupWithId(group.identifier, withLightState: lightState,
                                                            completionHandler: { (error) in
                                                                guard error == nil else {
                                                                    print("Error setLightStateForGroupWithId: ",
                                                                          String(describing: error?.description))
                                                                    return
                                                                }
                                                                completion()
        })
    }

    func setLightState(for light: Light, using swiftyHue: SwiftyHue,
                       with lightState: LightState, completion: (() -> Void)?) {
        swiftyHue.bridgeSendAPI.updateLightStateForId(light.identifier, withLightState: lightState,
                                                      completionHandler: { (error) in
                                                        guard error == nil else {
                                                            print("Error updateLightStateForId: ",
                                                                  String(describing: error?.description))
                                                            return
                                                        }
                                                        completion?()
        })
    }

    func getAverageBrightnessOfLightsInGroup(_ lights: [Light]) -> Int {
        var averageBrightnessOfLightsOn: Int = 0
        for light in lights where light.state.on! == true {
            averageBrightnessOfLightsOn += light.state.brightness!
        }
        return averageBrightnessOfLightsOn
    }

    func getNumberOfLightsOnInGroup(_ lights: [Light]) -> Int {
        var numberOfLightsOn: Int = 0
        for light in lights where light.state.on! == true {
            numberOfLightsOn += 1
        }
        return numberOfLightsOn
    }

    private var previousTimer: Timer? = nil {
        willSet {
            previousTimer?.invalidate()
        }
    }
    func sendTimeSensistiveAPIRequest(completion: @escaping () -> Void) {
        guard previousTimer == nil else { return }
        previousTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false, block: { _ in
            self.previousTimer = nil
            completion()
        })
    }

    func getLightImageName(modelId: String) -> String {
        switch modelId {
        case "LCT001", "LCT007", // E27/A19/B22, Classic bulbs
             "LCT010", "LCT014",
             "LCT015", "LCT016",
             "LTW004", "LTW010",
             "LTW015", "LTW001":
            return "bulbsSultan"
        case "LCT002", "LCT011", // BR30 ceiling bulbs, Flood Bulbs
             "LTW011":
            return "bulbFlood"
        case "LCT003":           // GU/PAR Bulbs, spot-like lights
            return "bulbsSpot"
        case "LST001", "LST002": // LightStrips
            return "heroesLightstrip"
        default:
            print("Error getting image from modelId", modelId)
            return ""
        }
    }
}
