//
//  RGBColorUtilities.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 10/14/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import UIKit

class RGBColorUtilities {
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
