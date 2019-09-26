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

    weak var addColorDelegate: DynamicSceneAddColorDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 13.0, *) {
            self.navigationController?.isModalInPresentation = true
        }

        swiftyHue = RGBRequest.shared.getSwiftyHue()

        brightnessSlider.isHidden = true
        colorPreview.isHidden = true

//        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel,
//                                                            target: self, action: #selector(cancel))

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save,
                                                            target: self, action: #selector(save))
    }

    @objc func save() {
        navigationController?.popViewController(animated: true)
        let xyPoint: CGPoint = HueUtilities.calculateXY(self.colorPicker.selectedColor, forModel: "LCT016")
        addColorDelegate?.dynamicSceneColorAdded(XYColor([Double(xyPoint.x), Double(xyPoint.y)]))
    }
//
//    @objc func cancel() {
//        dismiss(animated: true, completion: nil)
//    }
}
