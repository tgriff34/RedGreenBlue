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
    var lights: [String: Light]?
    var lightIdentifiers: [String]?
    var lightState: LightState?

    override func viewDidLoad() {
        super.viewDidLoad()

        brightnessSlider.isHidden = true
        colorPreview.isHidden = true

        guard let lights = lights else {
            return
        }

        guard let lightState = lightState else {
            return
        }

        lightIdentifiers = RGBGroupsAndLightsHelper.retrieveLightIds(from: lights)

        colorPicker.selectedColor = HueUtilities.colorFromXY(CGPoint(x: lightState.xy![0], y: lightState.xy![1]),
                                                             forModel: lights[lightIdentifiers![0]]!.modelId)

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

        guard let lightIdentifiers = lightIdentifiers else {
            return
        }

        for identifier in lightIdentifiers {
            guard let light = lights[identifier] else {
                return
            }
            let xyPoint: CGPoint = HueUtilities.calculateXY(selectedColor, forModel: light.modelId)
            var lightState = LightState()
            lightState.xy = [Double(xyPoint.x), Double(xyPoint.y)]
            swiftyHue?
                .bridgeSendAPI
                .updateLightStateForId(identifier, withLightState: lightState,
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
