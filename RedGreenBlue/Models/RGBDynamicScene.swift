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
    @objc dynamic var brightnessDifference: Int = 0
    @objc dynamic var isDefault: Bool = false
    @objc dynamic var sequentialLightChange: Bool = false
    @objc dynamic var randomColors: Bool = false
    var xys = List<XYColor>()

    convenience init(name: String, timer: Double, brightnessDifference: Int,
                     isDefault: Bool, sequentialLightChange: Bool, randomColors: Bool) {
        self.init()
        self.name = name
        self.timer = timer
        self.brightnessDifference = brightnessDifference
        self.isDefault = isDefault
        self.sequentialLightChange = sequentialLightChange
        self.randomColors = randomColors
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