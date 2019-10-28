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

    // Sets lights state for an entire group
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

    // Sets light state for a single light
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

    // Gets the average brights of lights that are on in a group
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

    // This var and the following func prevents the app from sending to many API calls to the bridge.
    // If the user sends too many API call to quickly the calls stack up and the lights look out of sync.
    // 0.25 is the fastest timeInterval recommended when calling this function
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

    // Retrieves light image from xcassets folder based on the modelId of the light
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
    private var player: AVQueuePlayer?
    private var looper: AVPlayerLooper?
    private var timeObserver: NSObjectProtocol?
    private var observer: NSObjectProtocol?
    private var playingScene: RGBDynamicScene?
    private func makePlayer(file: String) -> AVQueuePlayer {
        guard let url: URL = Bundle.main.url(forResource: file, withExtension: "mp3") else {
            logger.error("Error getting song file \(file).")
            fatalError("Error getting song file \(file).")
        }
        let player = AVQueuePlayer(url: url)
        // Observer when the song ends, the looper automatically handles replaying the song
        // this make sures that all the lights for the scenes get removed.
        if let observer = observer { NotificationCenter.default.removeObserver(observer) }
        observer = NotificationCenter.default.addObserver(
            forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player.currentItem,
            queue: .main, using: { _ in
                self.lightsForScene.removeAll()
        })
        // Observer for audio interrupts, this allows the app to pause the song and
        // reflect that in the UI. Also allows the app to resume playing after the interruption
        NotificationCenter.default.addObserver(
            self, selector: #selector(audioSessionInterruption(_:)),
            name: AVAudioSession.interruptionNotification, object: nil)
        return player
    }

    func playDynamicScene(scene: RGBDynamicScene, for group: RGBGroup, with swiftyHue: SwiftyHue) {
        // Make sure that there was no scene playing before, if so stop it.
        stopDynamicScene()
        playingScene = scene
        // Instantiate a new audio player with the sound file associated with the scene
        // Also sets up the looper.
        player = self.makePlayer(file: scene.soundFile)
        looper = AVPlayerLooper(player: player!, templateItem: player!.currentItem!)
        do {
            try AVAudioSession.sharedInstance().setCategory(
                AVAudioSession.Category.playback,
                mode: .default, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true, options: [])
        } catch {
            logger.error("Failed to set audio session category. Error: \(error)")
        }

        // Determine which timer is shorter (brightness or color timer).  That time will
        // then be used in the periodic time observer so that the scene can change according
        // to the option.
        var timer: Double = 30
        if scene.lightsChangeColor && scene.isBrightnessEnabled {
            timer = scene.timer < scene.brightnessTimer ? scene.timer: scene.brightnessTimer
        } else if scene.lightsChangeColor && !scene.isBrightnessEnabled {
            timer = scene.timer
        } else if !scene.lightsChangeColor && scene.isBrightnessEnabled {
            timer = scene.brightnessTimer
        }

        lightsForScene.removeAll()
        // If the user doesn't have the colors of the lights changing, run it through the
        // setLightsForScene() once to get the colors associated with the scene.
        if !scene.lightsChangeColor {
            self.setLightsForScene(group: group, numberOfColors: scene.xys.count,
                                   multiColors: scene.displayMultipleColors,
                                   isSequential: scene.sequentialLightChange,
                                   randomColors: scene.randomColors)
        }

        // Periodic time observer, will re-set the scene based on the timer instantiated above
        self.timeObserver = player?.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: timer, preferredTimescale: 1),
            queue: DispatchQueue.main, using: { time in
                self.setScene(scene: scene, for: group, time: Int(CMTimeGetSeconds(time)), with: swiftyHue)
        }) as? NSObjectProtocol

        // Determines whether the audio should be muted based on the option selected in the options menu
        if let setting = UserDefaults.standard.object(forKey: "SoundSetting") as? String,
            setting == "Muted" {
            player?.isMuted = true
        }

        // Play scene
        player?.play()
    }

    // Stop player, remove observer, make looper and player nil for reinstantiation
    func stopDynamicScene() {
        player?.pause()
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                                  object: nil)
        player?.removeTimeObserver(timeObserver as Any)
        playingScene = nil
        looper = nil
        player = nil
    }

    func getPlayingScene() -> RGBDynamicScene? {
        return playingScene
    }

    private var lightsForScene = [Int]()
    // Makes API calls to set the color/brightness for the lights based on the scene
    private func setScene(scene: RGBDynamicScene, for group: RGBGroup, time: Int, with swiftyHue: SwiftyHue) {
        // Determine what should change during the call based on the time that the user
        // set for when colors and brightness change and the current song time.
        // If the remainder is 0 it should be set.
        let (_, remainderForColor) = time.quotientAndRemainder(dividingBy: Int(scene.timer))
        let (_, remainderForBrightness) = time.quotientAndRemainder(dividingBy: Int(scene.brightnessTimer))

        // This block prevents a crash when getting the duration of the current playing song
        // that is used in the if statement afterwards.
        var durationTime: Int?
        if let currentItem = player?.currentItem, currentItem.status == AVPlayerItem.Status.readyToPlay {
            durationTime = Int(CMTimeGetSeconds(currentItem.duration))
        }

        // The colors need to change
        if remainderForColor == 0 && scene.lightsChangeColor && (lightsForScene.isEmpty || time != 0)
            && durationTime != time {
            setLightsForScene(group: group, numberOfColors: scene.xys.count,
                              multiColors: scene.displayMultipleColors,
                              isSequential: scene.sequentialLightChange, randomColors: scene.randomColors)
        }

        for (index, light) in group.lights.enumerated() {
            // Create lightstate and turn light on
            var lightState = LightState()
            lightState.on = true

            // Get which color index this light should be
            var lightIndex = lightsForScene[0]
            if scene.displayMultipleColors {
                lightIndex = lightsForScene[index]
            }

            console.debug("LightsForScene: \(lightsForScene)")

            // Set the color of the light based on the previous index
            lightState.xy = [scene.xys[lightIndex].xvalue, scene.xys[lightIndex].yvalue]

            // Set the brightness for the light
            if remainderForBrightness == 0 && scene.isBrightnessEnabled {
                lightState.brightness = genRandomNum(minBrightness: scene.minBrightness,
                                                     maxBrightness: scene.maxBrightness)
            }

            // Send API request to change light
            setLightState(for: light, using: swiftyHue, with: lightState, completion: nil)
        }
    }

    // Determines which color the lights should be
    private func setLightsForScene(group: RGBGroup, numberOfColors: Int, multiColors: Bool,
                                   isSequential: Bool, randomColors: Bool) {
        // Set lights array whether lights should be in order of them picked or randomized
        let groupLights = group.lights
        if (numberOfColors > groupLights.count || !multiColors) && lightsForScene.isEmpty {
            lightsForScene = Array(0..<numberOfColors)
        } else if lightsForScene.isEmpty {
            for _ in groupLights {
                if randomColors {
                    lightsForScene.append(genRandomNum(numberOfColors: numberOfColors))
                } else {
                    let count = groupLights.count - 1
                    lightsForScene = Array(repeating: 0..<numberOfColors, count: count).flatMap({$0})
                    lightsForScene = Array(lightsForScene[...count])
                }
            }
        }

        if isSequential || !multiColors { // If it's sequential just shift to right
            lightsForScene = lightsForScene.shiftRight()
        } else { // Otherwise randomly shuffle
            lightsForScene.shuffle()
        }
    }

    // Generates a random number based on the number of colors associated with the scene.
    // It makes sure that all colors will be displayed if there are enough lights to support that.
    private func genRandomNum(numberOfColors: Int) -> Int {
        var randomNumber = Int(arc4random_uniform(UInt32(numberOfColors)))
        if lightsForScene.count < numberOfColors {
            while lightsForScene.contains(randomNumber) {
                randomNumber = Int(arc4random_uniform(UInt32(numberOfColors)))
            }
        }
        return randomNumber
    }

    // Generates a random brightness between the two brightness values provided.
    private func genRandomNum(minBrightness: Int, maxBrightness: Int) -> Int {
        let randomNumber = Int(arc4random_uniform(UInt32(maxBrightness))) + minBrightness
        return Int(Double(randomNumber) * 2.54)
    }
}

extension RGBGroupsAndLightsHelper {
    @objc func audioSessionInterruption(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo,
            let typeInt = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeInt) else {
            return
        }
        switch type {
        case .began:
            player?.pause()
        case .ended:
            if let optionInt = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionInt)
                if options.contains(.shouldResume) {
                    player?.play()
                }
            }
        @unknown default:
            logger.error("Unknown case for \(type)")
        }
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
