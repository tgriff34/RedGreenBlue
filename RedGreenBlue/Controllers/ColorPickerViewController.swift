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

    var swiftyHue: SwiftyHue?
    var lights: [String]?
    var lightState: LightState?

    override func viewDidLoad() {
        super.viewDidLoad()

        brightnessSlider.isHidden = true
        colorPreview.isHidden = true

        colorPicker.selectedColor = UIColor(hue: CGFloat(lightState!.hue!) / 65280,
                                            saturation: CGFloat(lightState!.saturation!) / 254,
                                            brightness: 1, alpha: 1)

        colorPicker.radialHsbPalette?.addTarget(self, action: #selector(touchUpInside(_:)), for: .valueChanged)
    }

    // Only send a request to the lights
    @objc func touchUpInside(_ sender: RadialPaletteControl) {
        RGBGroupsAndLightsHelper.sendTimeSensistiveAPIRequest {
            self.setLightColor(color: sender.selectedColor)
        }
    }

    // Setting light colors
    func setLightColor(color: UIColor) {
        guard let lights = lights else {
            print("Error receiving lights from LightTableViewController, lights are nil")
            return
        }

        // Get Hue and Saturation from UIColor being passed in
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        // Create light state
        var lightState = LightState()
        if lights.count == 1 { // If only one light is selected turn it on, if its a group don't turn on off lights
            lightState.on = true
        }
        // Convert hue and saturation to a number the API understands
        lightState.hue = Int(hue * 65280)
        lightState.saturation = Int(saturation * 254)

        // For every light in lights send the API request to bridge and set the lightstate of the light
        for light in lights {
            swiftyHue?
                .bridgeSendAPI
                .updateLightStateForId(light, withLightState: lightState,
                                       completionHandler: { (error) in
                                        guard error == nil else {
                                            print("Error updateLightStateForId in setLightColor(_:_:) - ",
                                                  String(describing: error?.description))
                                            return
                                        }
            })
        }
    }
}
