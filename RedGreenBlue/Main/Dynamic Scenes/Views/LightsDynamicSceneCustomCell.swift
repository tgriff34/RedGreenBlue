//
//  LightsDynamicSceneCustomCell.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 9/18/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import UIKit
import SwiftyHue

class LightsDynamicSceneCustomCell: UITableViewCell {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var subView: GradientLayerView!
    @IBOutlet weak var `switch`: UISwitch!

    weak var delegate: DynamicSceneCellDelegate?
    var gradientLayer = CAGradientLayer()

    var dynamicScene: RGBDynamicScene! {
        didSet {
            self.label.text = dynamicScene.name
            var uiColors = dynamicScene.colors
            if uiColors.count > 1 {
                subView.backgroundColor = nil
                uiColors.sort(by: { $0.hue < $1.hue })
                subView.layer.colors = uiColors.map({ return $0.cgColor })
            } else {
                subView.backgroundColor = uiColors[0]
                subView.layer.colors = nil
            }
            label.textColor = RGBCellUtilities.colorForLabel(from: uiColors)
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        self.switch.setOn(selected, animated: true)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        RGBCellUtilities.setCellLayerStyleAttributes(subView)

        subView.layer.startPoint = CGPoint(x: 0.0, y: 0.5)
        subView.layer.endPoint = CGPoint(x: 1.0, y: 0.5)

        self.switch.addTarget(self, action: #selector(sceneSwitchTapped(_:)), for: .valueChanged)
    }

    @objc func sceneSwitchTapped(_ sender: UISwitch!) {
        delegate?.dynamicSceneTableView(self, sceneSwitchTappedFor: dynamicScene)
    }
}
