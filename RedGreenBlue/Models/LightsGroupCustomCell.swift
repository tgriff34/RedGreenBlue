//
//  LightsGroupCustomCell.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 8/16/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import UIKit
import fluid_slider

class LightsGroupCustomCell: UITableViewCell {
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var numberOfLightsLabel: UILabel!
    @IBOutlet weak var `switch`: UISwitch!
    @IBOutlet weak var slider: Slider!
    @IBOutlet weak var subView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        subView.layer.cornerRadius = 20.0
    }
}
