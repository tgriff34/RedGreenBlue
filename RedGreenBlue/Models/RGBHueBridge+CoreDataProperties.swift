//
//  RGBHueBridge+CoreDataProperties.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 1/13/20.
//  Copyright © 2020 Dana Griffin. All rights reserved.
//
//

import Foundation
import CoreData

extension RGBHueBridge {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<RGBHueBridge> {
        return NSFetchRequest<RGBHueBridge>(entityName: "RGBHueBridge")
    }

    @NSManaged public var deviceType: String
    @NSManaged public var friendlyName: String
    @NSManaged public var ipAddress: String
    @NSManaged public var modelDescription: String
    @NSManaged public var modelName: String
    @NSManaged public var serialNumber: String
    @NSManaged public var udn: String
    @NSManaged public var username: String

}
