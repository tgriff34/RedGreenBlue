//
//  FoundBridgesTableViewCell.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 10/14/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import UIKit

class FoundBridgesTableViewCell: UITableViewCell {
    var bridge: RGBHueBridge! {
        didSet {
            let string = bridge.friendlyName.components(separatedBy: " (")
            self.textLabel?.text = string[0]
            self.detailTextLabel?.text = bridge.ipAddress
        }
    }
}
