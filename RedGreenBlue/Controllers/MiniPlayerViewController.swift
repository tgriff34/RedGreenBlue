//
//  MiniPlayerViewController.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 9/10/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import Foundation
import UIKit
import SpriteKit
import SwiftyHue

class MiniPlayerViewController: UIViewController {

    var currentScene: RGBDynamicScene?
    var currentGroup: RGBGroup?
    var timers = [Timer?]()
    var swiftyHue: SwiftyHue!
    var isPlaying: Bool = false

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var button: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        swiftyHue = RGBRequest.shared.getSwiftyHue()
        button.addTarget(self, action: #selector(buttonChanged), for: .touchUpInside)
    }

    private func configureView(scene: RGBDynamicScene?, group: RGBGroup?) {
        if let scene = scene {
            label.text = scene.name
        } else {
            label.text = nil
        }
        currentScene = scene
        currentGroup = group
        setPlaying(isPlaying)
    }

    var previousIndices = [Int]()
    private func startScene(_ scene: RGBDynamicScene, for group: RGBGroup) {
        stopScene()
        previousIndices.removeAll()
        for (index, light) in group.lights.enumerated() {
            self.previousIndices.append(Int(arc4random_uniform(UInt32(scene.xys.count))))
            self.timers.append(Timer.scheduledTimer(withTimeInterval: scene.timer, repeats: true, block: { _ in
                // Create lightstate and turn light on
                var lightState = LightState()
                lightState.on = true

                // Set brightness for light within random range of upper / lower bounds
                let brightness = Int(arc4random_uniform(UInt32(scene.upperBrightness - scene.bottomBrightness))
                    + UInt32(scene.bottomBrightness))
                lightState.brightness = brightness

                // Set xy color value to random xy in array without repeating same color
                var randomNum = Int(arc4random_uniform(UInt32(scene.xys.count)))
                while self.previousIndices[index] == randomNum {
                    randomNum = Int(arc4random_uniform(UInt32(scene.xys.count)))
                }
                self.previousIndices[index] = randomNum
                lightState.xy = [scene.xys[randomNum].xvalue, scene.xys[randomNum].yvalue]

                RGBGroupsAndLightsHelper.shared.setLightState(for: light, using: self.swiftyHue,
                                                              with: lightState, completion: nil)
            }))
        }
    }

    private func stopScene() {
        for var timer in timers {
            timer?.invalidate()
            timer = nil
        }
        timers.removeAll()
    }

    private func setPlaying(_ playing: Bool) {
        guard let scene = currentScene else {
            return
        }
        guard let group = currentGroup else {
            return
        }
        if isPlaying {
            button.titleLabel?.text = "Play"
            stopScene()
        } else {
            button.titleLabel?.text = "Pause"
            startScene(scene, for: group)
        }
    }

    @objc func buttonChanged() {
        isPlaying = !isPlaying
        setPlaying(isPlaying)
    }
}

extension MiniPlayerViewController: MiniPlayerDelegate {
    func miniPlayer(play scene: RGBDynamicScene, for group: RGBGroup) {
        configureView(scene: scene, group: group)
    }
}
