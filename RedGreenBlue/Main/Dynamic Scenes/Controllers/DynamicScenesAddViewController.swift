//
//  DynamicScenesAddViewController.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 9/24/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import UIKit
import RealmSwift
import MARKRangeSlider

class DynamicScenesAddViewController: UITableViewController {

    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var fluctuatingBrightnessSwitch: UISwitch!
    @IBOutlet weak var brightnessSlider: MARKRangeSlider!

    var scene: RGBDynamicScene?
    var name: String = ""
    var colors = List<XYColor>()
    // Light Color Options
    var lightsChangeColor: Bool = true
    var time: Int = 1
    var multiColors: Bool = true
    var randomColors: Bool = true
    var shiftRight: Bool = true
    // Light Brightness Options
    var brightnessTime: Int = 1
    var minBrightness: Int = 25
    var maxBrightness: Int = 75
    // Sound File
    var soundFileName: String = "Default"

    weak var addSceneDelegate: DynamicSceneAddDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Navbar items
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel,
                                                           target: self, action: #selector(cancel))

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save,
                                                            target: self, action: #selector(save))
        // Set controller to textfield delegate
        textField.delegate = self
        textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)

        // Option switch actions
        fluctuatingBrightnessSwitch.addTarget(
            self, action: #selector(fluctuatingBrightnessTapped(_:)), for: .valueChanged)

        // Fluctuating brightness slider default values/init
        brightnessSlider.setMinValue(1, maxValue: 100)
        brightnessSlider.setLeftValue(25, rightValue: 75)
        brightnessSlider.minimumDistance = 1
        brightnessSlider.backgroundColor = tableView.cellForRow(at: IndexPath(row: 1, section: 4))?.backgroundColor

        // Set the track image on the fluctuating brightness color to blue
        guard let arrayOfImages = brightnessSlider.subviews as? [UIImageView],
            arrayOfImages.indices.contains(1) else { return }

        let trackImage = arrayOfImages[1]
        trackImage.image = trackImage.image?.withRenderingMode(.alwaysTemplate)
        trackImage.tintColor = view.tintColor

        // Set fluctating brightness slider action
        brightnessSlider.addTarget(
            self, action: #selector(brightSliderValueChanged(_:)), for: .valueChanged)

        // If the user is editing a scene, set the variables to scene values
        setSceneIfEditing()
    }

    @objc func viewTapped() {
        self.view.endEditing(true)
    }

    @objc func save() {
        // Create new scene to populate DB with
        let scene = RGBDynamicScene(
            name: self.name, timer: Double(time), isDefault: false,
            lightsChangeColor: lightsChangeColor,
            displayMultipleColors: multiColors,
            sequentialLightChange: shiftRight,
            randomColors: randomColors, soundFile: soundFileName,
            isBrightnessEnabled: fluctuatingBrightnessSwitch.isOn, brightnessTimer: Double(brightnessTime),
            minBrightness: minBrightness, maxBrightness: maxBrightness)

        scene.xys = self.colors
        // If the self.scene isn't nil then the user was editing a previous scene
        // and we should let the delegate know, otherwise the scene is new
        if self.scene != nil {
            addSceneDelegate?.dynamicSceneEdited(self, scene)
        } else {
            addSceneDelegate?.dynamicSceneAdded(self, scene)
        }
    }

    @objc func cancel() {
        dismiss(animated: true, completion: nil)
    }

    @objc func fluctuatingBrightnessTapped(_ sender: UISwitch) {
        tableView.reloadSections([3], with: .automatic)
        tableView.reloadRows(at: [IndexPath(row: 0, section: 2)], with: .none)
    }

    @objc func brightSliderValueChanged(_ sender: MARKRangeSlider) {
        minBrightness = Int(sender.leftValue)
        maxBrightness = Int(sender.rightValue)
        let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 2))
        cell?.detailTextLabel?.text = "\(minBrightness)% - \(maxBrightness)%"
    }

    private func setSceneIfEditing() {
        if let scene = scene {
            for color in scene.xys { // needs to copy instead of assigning as reference
                colors.append(XYColor([color.xvalue, color.yvalue]))
            }
            time = Int(scene.timer)
            name = String(scene.name)
            lightsChangeColor = scene.lightsChangeColor
            shiftRight = scene.sequentialLightChange
            multiColors = scene.displayMultipleColors
            randomColors = scene.randomColors
            soundFileName = scene.soundFile
            fluctuatingBrightnessSwitch.isOn = scene.isBrightnessEnabled
            brightnessTime = Int(scene.brightnessTimer)
            minBrightness = scene.minBrightness
            maxBrightness = scene.maxBrightness
            brightnessSlider.setLeftValue(CGFloat(scene.minBrightness), rightValue: CGFloat(scene.maxBrightness))
            tableView.reloadRows(at: [IndexPath(row: 0, section: 1), IndexPath(row: 1, section: 1),
                                      IndexPath(row: 0, section: 2), IndexPath(row: 0, section: 4)],
                                 with: .none)
        }
    }

    private func enableOrDisableSaveButton() {
        if colors.isEmpty || textField.text?.isEmpty ?? false {
            navigationItem.rightBarButtonItem?.isEnabled = false
        } else {
            navigationItem.rightBarButtonItem?.isEnabled = true
        }
    }
}

// MARK: - TableView
extension DynamicScenesAddViewController {
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 3:
            if !fluctuatingBrightnessSwitch.isOn {
                return 0.1
            }
        default:
            return super.tableView(tableView, heightForHeaderInSection: section)
        }
        return super.tableView(tableView, heightForHeaderInSection: section)
    }
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        switch section {
        case 3:
            if !fluctuatingBrightnessSwitch.isOn {
                return 0.1
            }
        default:
            return super.tableView(tableView, heightForFooterInSection: section)
        }
        return super.tableView(tableView, heightForFooterInSection: section)
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        if scene == nil {
            return 5
        }
        return 6
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 3:
            if fluctuatingBrightnessSwitch.isOn {
                return 2
            }
            return 0
        default:
            return super.tableView(tableView, numberOfRowsInSection: section)
        }
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        switch indexPath.section {
        case 0:
            textField.text = name
            enableOrDisableSaveButton()
        case 1:
            if indexPath.row == 0 {
                cell.detailTextLabel?.text = colors.count > 1 ? "\(colors.count) colors" : "\(colors.count) color"
            } else if indexPath.row == 1 {
                cell.detailTextLabel?.text = lightsChangeColor ? "On" : "Off"
            }
        case 2:
            if indexPath.row == 0 {
                cell.detailTextLabel?.text = fluctuatingBrightnessSwitch.isOn ?
                    "\(minBrightness)% - \(maxBrightness)%" : ""
            }
        case 3:
            if indexPath.row == 0 {
                cell.detailTextLabel?.text = brightnessTime > 1 ?
                    "\(brightnessTime) seconds" : "\(brightnessTime) second"
            }
        case 4:
            cell.detailTextLabel?.text = soundFileName
        default:
            logger.info("No action for \(indexPath.section)")
        }
        return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 5 {
            let actionSheet = UIAlertController(
                title: "Delete Scene", message: "Are you sure you want to delete this scene?",
                preferredStyle: .alert)
            let deleteAction = UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                self.addSceneDelegate?.dynamicSceneDeleted(self)
            })
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

            actionSheet.addAction(deleteAction)
            actionSheet.addAction(cancelAction)

            self.present(actionSheet, animated: true, completion: nil)
        }
    }
}

// MARK: - Navigation / Set Delegate to self
extension DynamicScenesAddViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "ColorsSegue":
            let viewController = segue.destination as? DynamicScenesColorsViewController
            viewController?.colors = colors
            viewController?.addColorsDelegate = self
        case "ChangingLightColorsSegue":
            let viewController = segue.destination as? DynamicScenesColorOptionsViewController
            viewController?.colorOptionsDelegate = self
            viewController?.lightsChangeColor =  lightsChangeColor
            viewController?.displayMultiColors = multiColors
            viewController?.randomColors = randomColors
            viewController?.shiftRight = shiftRight
            viewController?.time = time
        case "TimeBetweenChangingBrightnessSegue":
            let viewController = segue.destination as? DynamicScenesAddTimeViewController
            viewController?.addTimeDelegate = self
            viewController?.title = "Brightness Timer"
            viewController?.type = .brightness
            viewController?.selectedTime = brightnessTime
        case "SoundFileSegue":
            let viewController = segue.destination as? DynamicScenesAddSoundViewController
            viewController?.addSoundFileDelegate = self
            viewController?.selectedSoundFile = soundFileName
        default:
            logger.error("segue identifier does not exist: \(segue.identifier ?? "nil")")
        }
    }
}

// MARK: - Add Color / Time Delegate
extension DynamicScenesAddViewController: DynamicSceneAddAllColorsDelegate, DynamicSceneAddTimeDelegate,
DynamicSceneAddSoundFileDelegate, DynamicSceneColorOptionsDelegate {
    func lightsChangeColor(_ value: Bool) {
        self.lightsChangeColor = value
        tableView.reloadRows(at: [IndexPath(row: 1, section: 1)], with: .none)
    }

    func timeBetweenCycle(_ time: Int) {
        self.time = time
    }

    func lightsMultiColor(_ value: Bool) {
        self.multiColors = value
    }

    func lightsRandomColor(_ value: Bool) {
        self.randomColors = value
    }

    func lightsShiftRight(_ value: Bool) {
        self.shiftRight = value
    }

    func dynamicSceneSoundFileAdded(_ name: String) {
        self.soundFileName = name
        tableView.reloadRows(at: [IndexPath(row: 0, section: 4)], with: .none)
    }

    func dynamicSceneColorsAdded(_ colors: List<XYColor>) {
        self.colors = colors
        tableView.reloadRows(at: [IndexPath(row: 0, section: 1)], with: .none)
        enableOrDisableSaveButton()
    }

    func dynamicSceneTimeAdded(_ type: TimeType, _ time: Int) {
        self.brightnessTime = time
        tableView.reloadRows(at: [IndexPath(row: 0, section: 3)], with: .none)
    }
}

// MARK: - TextField Delegate
extension DynamicScenesAddViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    @objc func textFieldDidChange(_ textField: UITextField) {
        self.name = textField.text ?? ""
        enableOrDisableSaveButton()
    }
}
