//
//  ColorPickerViewController.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 8/22/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import UIKit
import FlexColorPicker
import SwiftyHue
import RealmSwift

class ColorPickerViewController: UIViewController {
    var swiftyHue: SwiftyHue!
    var lights = [Light]()

    @IBOutlet weak var containerView: UIView!

    weak var addColorDelegate: DynamicSceneColorDelegate?
    weak var customColorDelegate: DynamicSceneCustomColorDelegate?

    var selectedColor: XYColor?

    var segmentedControl: UISegmentedControl?

    private lazy var customColorPickerViewController: DefaultColorPickerViewController = {
        let storyboard = UIStoryboard(name: "DynamicScenes", bundle: Bundle.main)
        var viewController = storyboard.instantiateViewController(
            withIdentifier: "CustomColorPickerStoryboard") as? DefaultColorPickerViewController
        viewController?.brightnessSlider.isHidden = true
        viewController?.colorPreview.displayHex = false
        viewController?.colorPreview.cornerRadius = 20
        for light in lights where light.state.on! {
            viewController?.colorPicker.selectedColor = HueUtilities.colorFromXY(
                CGPoint(x: light.state.xy![0], y: light.state.xy![1]),
                forModel: light.modelId)
            break
        }
        self.add(asChildViewController: viewController!)
        return viewController!
    }()

    private lazy var defaultColorPickerViewController: DynamicScenesColorsPickerViewController = {
        let storyboard = UIStoryboard(name: "DynamicScenes", bundle: Bundle.main)
        var viewController = storyboard.instantiateViewController(
            withIdentifier: "DefaultColorPickerStoryboard") as? DynamicScenesColorsPickerViewController
        viewController?.delegate = self
        viewController?.collectionView.allowsMultipleSelection = false
        viewController?.selectedColor = XYColor([lights[0].state.xy![0], lights[0].state.xy![1]])
        self.add(asChildViewController: viewController!)
        return viewController!
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        let items = ["Custom", "Picker"]
        segmentedControl = UISegmentedControl(items: items)
        segmentedControl?.addTarget(self, action: #selector(segmentedControlChanged(_:)), for: .valueChanged)
        self.navigationItem.titleView = segmentedControl

        segmentedControl?.selectedSegmentIndex = 0
        segmentedControl?.sendActions(for: .valueChanged)

        customColorPickerViewController.colorPicker.radialHsbPalette?.addTarget(
            self, action: #selector(colorPickerTouchUpInside(_:)), for: .valueChanged)

        selectedColor = XYColor([lights[0].state.xy![0], lights[0].state.xy![1]])
    }

    @objc func segmentedControlChanged(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            remove(asChildViewController: defaultColorPickerViewController)
            add(asChildViewController: customColorPickerViewController)
            if let selectedColor = selectedColor {
                customColorPickerViewController.selectedColor = HueUtilities.colorFromXY(
                    CGPoint(x: selectedColor.xvalue, y: selectedColor.yvalue),
                    forModel: "LCT016")
            }
        } else {
            remove(asChildViewController: customColorPickerViewController)
            add(asChildViewController: defaultColorPickerViewController)
            defaultColorPickerViewController.selectedColor = selectedColor
        }
    }

    @objc func colorPickerTouchUpInside(_ sender: RadialPaletteControl) {
        RGBGroupsAndLightsHelper.shared.sendTimeSensistiveAPIRequest(withTimeInterval: 0.25, completion: {
            self.setLightColor(color: sender.selectedColor)
        })
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

    // Setting light colors
    private func setLightColor(color: UIColor? = nil, xyColor: XYColor? = nil) {
        var turnOnLights: Bool = false
        if RGBGroupsAndLightsHelper.shared.getNumberOfLightsOnInGroup(lights) == 0 {
            turnOnLights = true
        }

        for light in self.lights where light.state.on! || turnOnLights {
            var lightState = LightState()
            if let color = color {
                let xyPoint: CGPoint = HueUtilities.calculateXY(color, forModel: light.modelId)
                lightState.xy = [Double(xyPoint.x), Double(xyPoint.y)]
                selectedColor = XYColor(lightState.xy!)
            } else if let xyColor = xyColor {
                lightState.xy = [xyColor.xvalue, xyColor.yvalue]
                selectedColor = xyColor
            }
            if turnOnLights { lightState.on = true }
            RGBGroupsAndLightsHelper.shared.setLightState(for: light, using: self.swiftyHue,
                                                          with: lightState, completion: nil)
        }
    }
}

extension ColorPickerViewController: DynamicSceneCustomColorDelegate {
    func dynamicSceneColorAdded(_ colors: List<XYColor>) {
    }

    func dynamicSceneColorEdited(_ color: XYColor) {
        self.setLightColor(xyColor: color)
    }
}
