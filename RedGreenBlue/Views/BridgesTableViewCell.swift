//
//  BridgesTableViewCell.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 9/5/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import Foundation
import UIKit

class BridgesTableViewCell: UITableViewCell {

    var bridge: RGBHueBridge! {
        didSet {
            let string = bridge.friendlyName.components(separatedBy: " (")
            self.textLabel?.text = string[0]
            self.detailTextLabel?.text = bridge.ipAddress
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
