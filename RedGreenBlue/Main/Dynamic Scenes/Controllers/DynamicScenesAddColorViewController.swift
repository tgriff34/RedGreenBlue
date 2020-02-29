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
import SwiftMessages

class DynamicScenesAddColorViewController: UIViewController {
    var swiftyHue: SwiftyHue?
    var colorToEdit: UIColor?
    var color: UIColor?
    var colors = [UIColor]()

    @IBOutlet weak var containerView: UIView!

    weak var addColorDelegate: DynamicSceneColorDelegate?
    weak var customColorDelegate: DynamicSceneCustomColorDelegate?

    var segmentedControl: UISegmentedControl?

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

    private lazy var defaultColorPickerViewController: DynamicScenesColorsPickerViewController = {
        let storyboard = UIStoryboard(name: "DynamicScenes", bundle: Bundle.main)
        var viewController = storyboard.instantiateViewController(
            withIdentifier: "DefaultColorPickerStoryboard") as? DynamicScenesColorsPickerViewController
        viewController?.delegate = self
        self.add(asChildViewController: viewController!)
        return viewController!
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        swiftyHue = RGBRequest.shared.getSwiftyHue()

        if colorToEdit != nil {
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save,
                                                                target: self, action: #selector(save))
        } else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Add", style: .plain,
                                                                target: self, action: #selector(save))
        }

        let items = ["Custom", "Picker"]
        segmentedControl = UISegmentedControl(items: items)
        segmentedControl?.addTarget(self, action: #selector(segmentedControlChanged(_:)), for: .valueChanged)
        self.navigationItem.titleView = segmentedControl

        segmentedControl?.selectedSegmentIndex = 0
        segmentedControl?.sendActions(for: .valueChanged)

        disableOrEnableAddButton()
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
            if let color = colorToEdit {
                customColorPickerViewController.colorPicker.selectedColor = color
            }
        } else {
            remove(asChildViewController: customColorPickerViewController)
            add(asChildViewController: defaultColorPickerViewController)
            if let color = colorToEdit {
                defaultColorPickerViewController.selectedColor = color
                defaultColorPickerViewController.collectionView.allowsMultipleSelection = false
            } else {
                defaultColorPickerViewController.selectedColors = colors
                defaultColorPickerViewController.collectionView.allowsMultipleSelection = true
            }
        }
        disableOrEnableAddButton()
    }

    @objc func save() {
        if let colorToEdit = colorToEdit {
            navigationController?.popViewController(animated: true)
            addColorDelegate?.dynamicSceneColorEdited(colorToEdit)
        } else {
            if segmentedControl?.selectedSegmentIndex == 0 {
                if let color = color {
                    addColorDelegate?.dynamicSceneColorAdded(color)
                } else {
                    addColorDelegate?.dynamicSceneColorAdded(customColorPickerViewController.colorPicker.selectedColor)
                }
            } else {
                customColorDelegate?.dynamicSceneColorAdded(colors)
                for indexPath in defaultColorPickerViewController.collectionView.indexPathsForSelectedItems! {
                    defaultColorPickerViewController.collectionView.deselectItem(at: indexPath, animated: true)
                }
                colors.removeAll()
                disableOrEnableAddButton()
            }
            let messageView = RGBSwiftMessages.createAlertInView(type: .success, fromNib: .cardView,
                                                                 content: ("Colors added!", ""))
            let config = RGBSwiftMessages.createMessageConfig(presentStyle: .bottom, windowLevel: .alert)
            SwiftMessages.show(config: config, view: messageView)
        }
    }

    private func disableOrEnableAddButton() {
        navigationItem.rightBarButtonItem?.isEnabled = !(colorToEdit == nil &&
            ((segmentedControl?.selectedSegmentIndex == 0 && color == nil) ||
            (segmentedControl?.selectedSegmentIndex == 1 && colors.isEmpty)))
    }
}

extension DynamicScenesAddColorViewController: ColorPickerDelegate, DynamicSceneCustomColorDelegate {
    func dynamicSceneColorEdited(_ color: UIColor) {
        self.colorToEdit = color
        disableOrEnableAddButton()
    }
    func dynamicSceneColorAdded(_ colors: [UIColor]) {
        self.colors = colors
        disableOrEnableAddButton()
    }
    func colorPicker(_ colorPicker: ColorPickerController, selectedColor: UIColor, usingControl: ColorControl) {
        if colorToEdit != nil {
            colorToEdit = customColorPickerViewController.colorPicker.selectedColor
        } else {
            color = customColorPickerViewController.colorPicker.selectedColor
        }
        disableOrEnableAddButton()
    }
    func colorPicker(_ colorPicker: ColorPickerController, confirmedColor: UIColor, usingControl: ColorControl) {
    }
}
