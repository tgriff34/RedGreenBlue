//
//  RGBDynamicScene+CoreDataProperties.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 1/13/20.
//  Copyright © 2020 Dana Griffin. All rights reserved.
//
//

import Foundation
import CoreData
import UIKit

extension RGBDynamicScene {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<RGBDynamicScene> {
        return NSFetchRequest<RGBDynamicScene>(entityName: "RGBDynamicScene")
    }

    @NSManaged public var brightnessTimer: Double
    @NSManaged public var categoryValue: Int32
    @NSManaged public var displayMultipleColors: Bool
    @NSManaged public var isBrightnessEnabled: Bool
    @NSManaged public var lightsChangeColor: Bool
    @NSManaged public var maxBrightness: Int64
    @NSManaged public var minBrightness: Int64
    @NSManaged public var name: String
    @NSManaged public var randomColors: Bool
    @NSManaged public var sequentialLightChange: Bool
    @NSManaged public var soundFile: String
    @NSManaged public var timer: Double
    @NSManaged public var colors: [UIColor]

}
