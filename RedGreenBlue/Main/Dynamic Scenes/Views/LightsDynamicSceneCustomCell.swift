//
//  LightsDynamicSceneCustomCell.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 9/18/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import UIKit

class LightsDynamicSceneCustomCell: UITableViewCell {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var subView: UIView!
    @IBOutlet weak var `switch`: UISwitch!

    weak var delegate: DynamicSceneCellDelegate?

    var dynamicScene: RGBDynamicScene! {
        didSet {
            self.label.text = dynamicScene.name
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selected {
            self.switch.setOn(true, animated: true)
        } else {
            self.switch.setOn(false, animated: true)
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        subView.layer.cornerRadius = 20.0
        if self.traitCollection.userInterfaceStyle != .dark {
            subView.layer.shadowColor = UIColor.gray.cgColor
            subView.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
            subView.layer.shadowOpacity = 0.7
            subView.layer.shadowRadius = 4.7
        }
        self.switch.addTarget(self, action: #selector(sceneSwitchTapped(_:)), for: .valueChanged)
    }

    @objc func sceneSwitchTapped(_ sender: UISwitch!) {
        delegate?.dynamicSceneTableView(self, sceneSwitchTappedFor: dynamicScene)
    }
}
