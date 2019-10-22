//
//  ColorPickerViewController.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 8/22/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import UIKit
import FlexColorPicker
import SwiftyHue

class ColorPickerViewController: DefaultColorPickerViewController {
    var swiftyHue: SwiftyHue!
    var lights = [Light]()

    override func viewDidLoad() {
        super.viewDidLoad()

        brightnessSlider.isHidden = true
        colorPreview.displayHex = false
        colorPreview.cornerRadius = 20

        for light in lights where light.state.on! {
            colorPicker.selectedColor = HueUtilities.colorFromXY(CGPoint(x: light.state.xy![0],
                                                                         y: light.state.xy![1]),
                                                                 forModel: light.modelId)
            break
        }

        colorPicker.radialHsbPalette?.addTarget(self, action: #selector(touchUpInside(_:)), for: .valueChanged)
    }

    // Only send a request to the lights
    @objc func touchUpInside(_ sender: RadialPaletteControl) {
        RGBGroupsAndLightsHelper.shared.sendTimeSensistiveAPIRequest(withTimeInterval: 0.25, completion: {
            self.setLightColor(color: sender.selectedColor)
        })
    }

    // Setting light colors
    private func setLightColor(color: UIColor) {
        var turnOnLights: Bool = false
        if RGBGroupsAndLightsHelper.shared.getNumberOfLightsOnInGroup(lights) == 0 {
            turnOnLights = true
        }

        for light in lights where light.state.on! || turnOnLights {
            let xyPoint: CGPoint = HueUtilities.calculateXY(selectedColor, forModel: light.modelId)
            var lightState = LightState()
            if turnOnLights { lightState.on = true }
            lightState.xy = [Double(xyPoint.x), Double(xyPoint.y)]
            RGBGroupsAndLightsHelper.shared.setLightState(for: light, using: swiftyHue,
                                                          with: lightState, completion: nil)
        }
    }
}
