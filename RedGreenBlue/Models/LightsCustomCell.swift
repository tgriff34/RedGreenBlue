//
//  LightsCustomCell.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 8/22/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import UIKit

class LightsCustomCell: UITableViewCell {
    @IBOutlet weak var `switch`: UISwitch!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var subView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        subView.layer.cornerRadius = 20.0
//        subView.layer.shadowColor = UIColor.gray.cgColor
//        subView.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
//        subView.layer.shadowRadius = 7.0
//        subView.layer.shadowOpacity = 0.4
    }
}
