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

    weak var delegate: DynamicSceneCellProtocol?

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
        self.switch.addTarget(self, action: #selector(sceneSwitchTapped(_:)), for: .valueChanged)
    }

    @objc func sceneSwitchTapped(_ sender: UISwitch!) {
        delegate?.dynamicSceneTableView(self, sceneSwitchTappedFor: dynamicScene)
    }
}
