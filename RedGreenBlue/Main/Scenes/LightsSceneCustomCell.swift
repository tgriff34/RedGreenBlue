//
//  LightsSceneCustomCell.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 8/29/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import UIKit

class LightSceneCustomCell: UITableViewCell {
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var subView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        subView.layer.cornerRadius = 20.0
        if self.traitCollection.userInterfaceStyle != .dark {
            subView.layer.shadowColor = UIColor.gray.cgColor
            subView.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
            subView.layer.shadowOpacity = 0.7
            subView.layer.shadowRadius = 4.7
        }
    }
}
