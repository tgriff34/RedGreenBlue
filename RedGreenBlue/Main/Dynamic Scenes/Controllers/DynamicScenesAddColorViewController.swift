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

class DynamicScenesAddColorViewController: UIViewController {
    var swiftyHue: SwiftyHue?
    var color: XYColor?

    @IBOutlet weak var containerView: UIView!

    weak var addColorDelegate: DynamicSceneAddColorDelegate?

    private lazy var customColorPickerViewController: DefaultColorPickerViewController = {
        let storyboard = UIStoryboard(name: "DynamicScenes", bundle: Bundle.main)
        var viewController = storyboard.instantiateViewController(
            withIdentifier: "CustomColorPickerStoryboard") as? DefaultColorPickerViewController
        viewController?.brightnessSlider.isHidden = true
        viewController?.colorPreview.displayHex = false
        viewController?.colorPreview.cornerRadius = 20
        viewController?.delegate = self
        self.add(asChildViewController: viewController!)
        return viewController!
    }()

    private lazy var defaultColorPickerViewController: DynamicScenesColorsCollectionPickerViewController = {
        let storyboard = UIStoryboard(name: "DynamicScenes", bundle: Bundle.main)
        var viewController = storyboard.instantiateViewController(
            withIdentifier: "DefaultColorPickerStoryboard") as? DynamicScenesColorsCollectionPickerViewController
        viewController?.delegate = self
        self.add(asChildViewController: viewController!)
        return viewController!
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        swiftyHue = RGBRequest.shared.getSwiftyHue()

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save,
                                                            target: self, action: #selector(save))

        let items = ["Custom", "Picker"]
        let segmentedControl = UISegmentedControl(items: items)
        segmentedControl.addTarget(self, action: #selector(segmentedControlChanged(_:)), for: .valueChanged)
        self.navigationItem.titleView = segmentedControl

        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.sendActions(for: .valueChanged)
    }

    private func add(asChildViewController viewController: UIViewController) {
        addChild(viewController)
        containerView.addSubview(viewController.view)
        viewController.view.frame = containerView.bounds
        viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        viewController.didMove(toParent: self)
    }

    private func remove(asChildViewController viewController: UIViewController) {
        viewController.willMove(toParent: nil)
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
    }

    @objc func segmentedControlChanged(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            remove(asChildViewController: defaultColorPickerViewController)
            add(asChildViewController: customColorPickerViewController)
            if let color = color {
                customColorPickerViewController.colorPicker.selectedColor = HueUtilities.colorFromXY(
                    CGPoint(x: color.xvalue, y: color.yvalue), forModel: "LCT016")
            }
        } else {
            remove(asChildViewController: customColorPickerViewController)
            add(asChildViewController: defaultColorPickerViewController)
            if let color = color {
                defaultColorPickerViewController.selectedColor = color
            }
        }
    }

    @objc func save() {
        navigationController?.popViewController(animated: true)
        if let color = color {
            addColorDelegate?.dynamicSceneColorAdded(color)
        } else {
            addColorDelegate?.dynamicSceneColorAdded(convertColorFromPicker())
        }
    }

    private func convertColorFromPicker() -> XYColor {
        let xyPoint: CGPoint = HueUtilities.calculateXY(
            customColorPickerViewController.colorPicker.selectedColor, forModel: "LCT016")
        return XYColor([Double(xyPoint.x), Double(xyPoint.y)])
    }
}

extension DynamicScenesAddColorViewController: ColorPickerDelegate, DynamicSceneAddColorDelegate {
    func dynamicSceneColorAdded(_ color: XYColor) {
        console.debug(color)
        self.color = color
    }
    func colorPicker(_ colorPicker: ColorPickerController, selectedColor: UIColor, usingControl: ColorControl) {
        color = convertColorFromPicker()
    }
    func colorPicker(_ colorPicker: ColorPickerController, confirmedColor: UIColor, usingControl: ColorControl) {
    }
}
