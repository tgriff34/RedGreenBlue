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
    var light: String?
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

    private var previousTimer: Timer? = nil {
        willSet {
            previousTimer?.invalidate()
        }
    }
    @objc func touchUpInside(_ sender: RadialPaletteControl) {
        guard previousTimer == nil else { return }
        previousTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false, block: { _ in
            self.setLightColor(color: sender.selectedColor)
        })
    }

    func setLightColor(color: UIColor) {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        var lightState = LightState()
        lightState.on = true
        lightState.hue = Int(hue * 65280)
        lightState.saturation = Int(saturation * 254)

        swiftyHue?
            .bridgeSendAPI
            .updateLightStateForId(light!, withLightState: lightState,
                                   completionHandler: { (error) in
                                    guard error == nil else {
                                        print("Error updateLightStateForId in setLightColor(_:_:) - ",
                                              String(describing: error?.description))
                                        return
                                    }
                                    self.previousTimer = nil
        })
    }
}
