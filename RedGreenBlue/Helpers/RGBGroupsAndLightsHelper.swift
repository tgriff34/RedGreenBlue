//
//  RGBGroupsAndLightsHelper.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 8/20/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import Foundation
import SwiftyHue
import AVFoundation

class RGBGroupsAndLightsHelper {
    static let shared = RGBGroupsAndLightsHelper()

    func setLightState(for group: RGBGroup, using swiftyHue: SwiftyHue,
                       with lightState: LightState, completion: @escaping () -> Void) {
        swiftyHue.bridgeSendAPI.setLightStateForGroupWithId(
            group.identifier, withLightState: lightState, completionHandler: { (error) in
                guard error == nil else {
                logger.warning("setLightStateForGroupWithId: ", String(describing: error?.description))
                return
            }
            completion()
        })
    }

    func setLightState(for light: Light, using swiftyHue: SwiftyHue,
                       with lightState: LightState, completion: (() -> Void)?) {
        swiftyHue.bridgeSendAPI.updateLightStateForId(
            light.identifier, withLightState: lightState, completionHandler: { (error) in
                guard error == nil else {
                    logger.warning("Error updateLightStateForId: ", String(describing: error?.description))
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
    func sendTimeSensistiveAPIRequest(withTimeInterval timeInterval: TimeInterval, completion: @escaping () -> Void) {
        guard previousTimer == nil else { return }
        previousTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false, block: { _ in
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
            logger.error("Error getting image from modelId", modelId)
            return ""
        }
    }

    // MARK: - Dynamic Scenes
    private var playerLooper: AVPlayerLooper?
    private func makePlayer(file: String) -> AVQueuePlayer {
        var url: URL?
        if file == "Default" {
            url = Bundle.main.url(forResource: "FeelinGood", withExtension: "mp3")
        } else {
            url = Bundle.main.url(forResource: file, withExtension: "mp3")
        }
        let player = AVQueuePlayer(url: url!)
        playerLooper = AVPlayerLooper(player: player, templateItem: player.currentItem!)
        return player
    }

    private var player: AVPlayer?
    func playDynamicScene(scene: RGBDynamicScene, for group: RGBGroup, with swiftyHue: SwiftyHue) {
        stopDynamicScene()
        player = self.makePlayer(file: scene.soundFile)
        do {
            try AVAudioSession.sharedInstance().setCategory(
                AVAudioSession.Category.playAndRecord,
                mode: .default, options: [])
        } catch {
            console.debug("Failed to set audio session category. Error: \(error)")
        }

        let timer = scene.timer < scene.brightnessTimer ? scene.timer: scene.brightnessTimer

        player?.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: timer, preferredTimescale: 1),
            queue: DispatchQueue.main, using: { time in
                self.setScene(scene: scene, for: group, time: Int(CMTimeGetSeconds(time)), with: swiftyHue)
        })
        if let setting = UserDefaults.standard.object(forKey: "SoundSetting") as? String,
            setting == "Muted" {
            player?.isMuted = true
        }
        player?.play()
    }

    func stopDynamicScene() {
        player?.pause()
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                                  object: nil)
        player = nil
    }

    private var lightsForScene = [Int]()

    private func setScene(scene: RGBDynamicScene, for group: RGBGroup, time: Int, with swiftyHue: SwiftyHue) {
        let (_, remainderForColor) = time.quotientAndRemainder(dividingBy: Int(scene.timer))
        let (_, remainderForBrightness) = time.quotientAndRemainder(dividingBy: Int(scene.brightnessTimer))
        if remainderForColor == 0 {
            lightsForScene.removeAll()
            setLightsForScene(group: group, numberOfColors: scene.xys.count,
                              isSequential: scene.sequentialLightChange, randomColors: scene.randomColors)
        }

        for (index, light) in group.lights.enumerated() {
            // Create lightstate and turn light on
            var lightState = LightState()
            lightState.on = true

            let lightIndex = lightsForScene[index]

            lightState.xy = [scene.xys[lightIndex].xvalue, scene.xys[lightIndex].yvalue]

            if remainderForBrightness == 0 && scene.isBrightnessEnabled {
                lightState.brightness = genRandomNum(minBrightness: scene.minBrightness,
                                                     maxBrightness: scene.maxBrightness)
            }

            setLightState(for: light, using: swiftyHue, with: lightState, completion: nil)
        }
    }

    private func setLightsForScene(group: RGBGroup, numberOfColors: Int, isSequential: Bool, randomColors: Bool) {
        // Set lights array whether lights should be in order of them picked or randomized
        let iterator = group.lights
        if numberOfColors > iterator.count && lightsForScene.isEmpty {
            lightsForScene = Array(0..<numberOfColors)
        } else {
            for _ in iterator where lightsForScene.count < iterator.count {
                if randomColors {
                    lightsForScene.append(genRandomNum(numberOfColors: numberOfColors))
                } else {
                    let count = iterator.count - 1
                    lightsForScene = Array(repeating: 0..<numberOfColors, count: count).flatMap({$0})
                    lightsForScene = Array(lightsForScene[...count])
                }
            }
        }

        if isSequential { // If it's sequential just shift to right
            lightsForScene = lightsForScene.shiftRight()
        } else { // Otherwise randomly shuffle
            lightsForScene.shuffle()
        }
    }

    private func genRandomNum(numberOfColors: Int) -> Int {
        var randomNumber = Int(arc4random_uniform(UInt32(numberOfColors)))
        if lightsForScene.count < numberOfColors {
            while lightsForScene.contains(randomNumber) {
                randomNumber = Int(arc4random_uniform(UInt32(numberOfColors)))
            }
        }
        return randomNumber
    }

    private func genRandomNum(minBrightness: Int, maxBrightness: Int) -> Int {
        let randomNumber = Int(arc4random_uniform(UInt32(maxBrightness))) + minBrightness
        return Int(Double(randomNumber) * 2.54)
    }
}

extension Array {
    func shiftRight(amount: Int = 1) -> [Element] {
        var amount = amount
        assert(-count...count ~= amount, "Shift amount out of bounds")
        if amount < 0 { amount += count }
        return Array(self[amount ..< count] + self[0 ..< amount])
    }
}
