//
//  RGBColorUtilities.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 10/14/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import UIKit

class RGBCellUtilities {
    static func colorForLabel(from colors: [UIColor]) -> UIColor {
        let firstColor = colors[0].cgColor
        var brightness = (firstColor.components![0] * 299)
        brightness += (firstColor.components![1] * 587)
        brightness += (firstColor.components![2] * 114)
        brightness /= 1000
        let floatBrightness = Float(brightness)
        if floatBrightness > 0.7 {
            return UIColor.black
        } else {
            return UIColor.white
        }
    }
    static func setImagesForSlider(_ slider: UISlider) {
        let minTrack = UIImage(named: "minTrack")?.resizableImage(withCapInsets:
            UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12))
        let maxTrack = UIImage(named: "maxTrack")?.resizableImage(withCapInsets:
            UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12))
        slider.setMinimumTrackImage(minTrack, for: .normal)
        slider.setMaximumTrackImage(maxTrack, for: .normal)
    }
}

extension UIColor {
    var hue: CGFloat {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        self.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        return hue
    }
}
