//
//  BridgeModel.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 8/16/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import SwiftyHue
import RealmSwift

class RGBHueBridge: Object {
    
    @objc dynamic var username: String = ""
    @objc dynamic var ipAddress: String = ""
    @objc dynamic var deviceType: String = ""
    @objc dynamic var friendlyName: String = ""
    @objc dynamic var modelDescription: String = ""
    @objc dynamic var modelName: String = ""
    @objc dynamic var serialNumber: String = ""
    
    convenience init(hueBridge: HueBridge) {
        self.init()
        self.ipAddress = hueBridge.ip
        self.deviceType = hueBridge.deviceType
        self.friendlyName = hueBridge.friendlyName
        self.modelDescription = hueBridge.modelDescription
        self.modelName = hueBridge.modelName
        self.serialNumber = hueBridge.serialNumber
    }
    
    override static func primaryKey() -> String? {
        return "ipAddress"
    }
    
}
