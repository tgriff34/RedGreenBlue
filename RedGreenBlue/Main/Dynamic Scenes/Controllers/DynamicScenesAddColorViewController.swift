//
//  DynamicScenesAddColorViewController.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 9/24/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import UIKit
import FlexColorPicker
import SwiftyHue

class DynamicScenesAddColorViewController: DefaultColorPickerViewController {
    var swiftyHue: SwiftyHue?
    var color: XYColor?

    weak var addColorDelegate: DynamicSceneAddColorDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        swiftyHue = RGBRequest.shared.getSwiftyHue()

        brightnessSlider.isHidden = true
        colorPreview.isHidden = true

        if let color = color {
            self.colorPicker.selectedColor = HueUtilities.colorFromXY(CGPoint(x: color.xvalue, y: color.yvalue),
                                                                      forModel: "LCT016")
        }

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save,
                                                            target: self, action: #selector(save))
    }

    @objc func save() {
        navigationController?.popViewController(animated: true)
        let xyPoint: CGPoint = HueUtilities.calculateXY(self.colorPicker.selectedColor, forModel: "LCT016")
        addColorDelegate?.dynamicSceneColorAdded(XYColor([Double(xyPoint.x), Double(xyPoint.y)]))
    }
}
