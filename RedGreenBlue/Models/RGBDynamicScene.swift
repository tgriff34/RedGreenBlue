//
//  RGBDynamicScene.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 9/10/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import Foundation
import RealmSwift

class RGBDynamicScene: Object {

    @objc dynamic var name: String = ""
    @objc dynamic var timer: Double = 0
    @objc dynamic var isDefault: Bool = false
    @objc dynamic var lightsChangeColor: Bool = false
    @objc dynamic var displayMultipleColors: Bool = false
    @objc dynamic var sequentialLightChange: Bool = false
    @objc dynamic var randomColors: Bool = false
    @objc dynamic var soundFile: String = ""
    @objc dynamic var isBrightnessEnabled: Bool = false
    @objc dynamic var brightnessTimer: Double = 0
    @objc dynamic var minBrightness: Int = 1
    @objc dynamic var maxBrightness: Int = 100
    var xys = List<XYColor>()

    convenience init(name: String, timer: Double, isDefault: Bool,
                     lightsChangeColor: Bool, displayMultipleColors: Bool,
                     sequentialLightChange: Bool, randomColors: Bool,
                     soundFile: String, isBrightnessEnabled: Bool, brightnessTimer: Double,
                     minBrightness: Int, maxBrightness: Int) {
        self.init()
        self.name = name
        self.timer = timer
        self.isDefault = isDefault
        self.lightsChangeColor = lightsChangeColor
        self.displayMultipleColors = displayMultipleColors
        self.sequentialLightChange = sequentialLightChange
        self.randomColors = randomColors
        self.soundFile = soundFile
        self.isBrightnessEnabled = isBrightnessEnabled
        self.brightnessTimer = brightnessTimer
        self.minBrightness = minBrightness
        self.maxBrightness = maxBrightness
    }

    override static func primaryKey() -> String? {
        return "name"
    }
}

class XYColor: Object {
    @objc dynamic var xvalue: Double = 0
    @objc dynamic var yvalue: Double = 0

    convenience init(_ xys: [Double]) {
        self.init()
        self.xvalue = xys[0]
        self.yvalue = xys[1]
    }
}
