//
//  BridgesTableViewCell.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 9/5/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class BridgesTableViewCell: UITableViewCell {

    var bridge: RGBHueBridge! {
        didSet {
            guard let ipAddress = bridge.value(forKeyPath: "ipAddress") as? String,
                let friendlyName = bridge.value(forKeyPath: "friendlyName") as? String else {
                return
            }
            let newFriendlyName = friendlyName.components(separatedBy: " (")
            self.textLabel?.text = newFriendlyName[0]
            self.detailTextLabel?.text = ipAddress
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        if selected {
            self.accessoryType = .checkmark
        } else {
            self.accessoryType = .none
        }
    }
}
