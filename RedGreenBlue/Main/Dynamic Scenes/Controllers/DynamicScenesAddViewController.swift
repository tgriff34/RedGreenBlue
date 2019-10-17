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
    @IBOutlet weak var lightsChangeColorSwitch: UISwitch!
    @IBOutlet weak var sequentialLightChangeSwitch: UISwitch!
    @IBOutlet weak var randomColorsSwitch: UISwitch!
    @IBOutlet weak var fluctuatingBrightnessSwitch: UISwitch!
    @IBOutlet weak var brightnessSlider: MARKRangeSlider!

    var scene: RGBDynamicScene?
    var colors = List<XYColor>()
    var time: Int = 1
    var name: String = ""
    var soundFileName: String = "Default"
    var brightnessTime: Int = 1
    var minBrightness: Int = 25
    var maxBrightness: Int = 75

    var tapRecognizer: UITapGestureRecognizer?

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

        // Tap recognizer to know when user taps to dismiss keyboard
        tapRecognizer = UITapGestureRecognizer()
        tapRecognizer?.addTarget(self, action: #selector(viewTapped))

        // Option switch actions
        lightsChangeColorSwitch.addTarget(
            self, action: #selector(lightsChangeColorTapped(_:)), for: .valueChanged)
        fluctuatingBrightnessSwitch.addTarget(
            self, action: #selector(fluctuatingBrightnessTapped(_:)), for: .valueChanged)

        // Fluctuating brightness slider default values/init
        brightnessSlider.setMinValue(1, maxValue: 100)
        brightnessSlider.setLeftValue(25, rightValue: 75)
        brightnessSlider.minimumDistance = 1
        brightnessSlider.backgroundColor = tableView.cellForRow(at: IndexPath(row: 0, section: 2))?.backgroundColor

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
        let scene = RGBDynamicScene(
            name: self.name, timer: Double(time), isDefault: false,
            lightsChangeColor: lightsChangeColorSwitch.isOn,
            sequentialLightChange: sequentialLightChangeSwitch.isOn,
            randomColors: randomColorsSwitch.isOn, soundFile: soundFileName,
            isBrightnessEnabled: fluctuatingBrightnessSwitch.isOn, brightnessTimer: Double(brightnessTime),
            minBrightness: minBrightness, maxBrightness: maxBrightness)

        scene.xys = self.colors
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
        tableView.reloadRows(at: [IndexPath(row: 0, section: 2)], with: .automatic)
        self.tableView.beginUpdates()
        self.tableView.endUpdates()
    }

    @objc func lightsChangeColorTapped(_ sender: UISwitch) {
        self.tableView.beginUpdates()
        self.tableView.endUpdates()
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
            lightsChangeColorSwitch.isOn = scene.lightsChangeColor
            sequentialLightChangeSwitch.isOn = scene.sequentialLightChange
            randomColorsSwitch.isOn = scene.randomColors
            soundFileName = scene.soundFile
            fluctuatingBrightnessSwitch.isOn = scene.isBrightnessEnabled
            brightnessTime = Int(scene.brightnessTimer)
            minBrightness = scene.minBrightness
            maxBrightness = scene.maxBrightness
            brightnessSlider.setLeftValue(CGFloat(scene.minBrightness), rightValue: CGFloat(scene.maxBrightness))
            tableView.reloadRows(at: [IndexPath(row: 0, section: 1), IndexPath(row: 1, section: 1),
                                      IndexPath(row: 0, section: 2), IndexPath(row: 0, section: 3)],
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
    override func numberOfSections(in tableView: UITableView) -> Int {
        if scene == nil {
            return 4
        }
        return 5
    }
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 1:
            if (indexPath.row == 2 || indexPath.row == 3 || indexPath.row == 4)
                && !lightsChangeColorSwitch.isOn {
                return 0
            }
        case 2:
            if (indexPath.row == 1 || indexPath.row == 2) && !fluctuatingBrightnessSwitch.isOn {
                return 0
            }
        default:
            break
        }
        return super.tableView(tableView, heightForRowAt: indexPath)
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
            } else if indexPath.row == 2 {
                cell.detailTextLabel?.text = time > 1 ? "\(time) seconds" : "\(time) second"
            }
        case 2:
            if indexPath.row == 0 {
                cell.detailTextLabel?.text = fluctuatingBrightnessSwitch.isOn ?
                    "\(minBrightness)% - \(maxBrightness)%" : ""
            } else if indexPath.row == 1 {
                cell.detailTextLabel?.text = brightnessTime > 1 ?
                    "\(brightnessTime) seconds" : "\(brightnessTime) second"
            }
        case 3:
            cell.detailTextLabel?.text = soundFileName
        default:
            logger.info("No action for \(indexPath.section)")
        }
        return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 4 {
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
        case "TimeBetweenChangingColorSegue":
            let viewController = segue.destination as? DynamicScenesAddTimeViewController
            viewController?.addTimeDelegate = self
            viewController?.type = .color
            viewController?.selectedTime = time
        case "TimeBetweenChangingBrightnessSegue":
            let viewController = segue.destination as? DynamicScenesAddTimeViewController
            viewController?.addTimeDelegate = self
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
DynamicSceneAddSoundFileDelegate {
    func dynamicSceneSoundFileAdded(_ name: String) {
        self.soundFileName = name
        tableView.reloadRows(at: [IndexPath(row: 0, section: 3)], with: .none)
    }

    func dynamicSceneColorsAdded(_ colors: List<XYColor>) {
        self.colors = colors
        tableView.reloadRows(at: [IndexPath(row: 0, section: 1)], with: .none)
        enableOrDisableSaveButton()
    }

    func dynamicSceneTimeAdded(_ type: TimeType, _ time: Int) {
        switch type {
        case .color:
            self.time = time
            tableView.reloadRows(at: [IndexPath(row: 2, section: 1)], with: .none)
        case .brightness:
            self.brightnessTime = time
            tableView.reloadRows(at: [IndexPath(row: 1, section: 2)], with: .none)
        }
    }
}

// MARK: - TextField Delegate
extension DynamicScenesAddViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        name = textField.text ?? ""
        self.view.removeGestureRecognizer(tapRecognizer!)
        enableOrDisableSaveButton()
    }
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.view.addGestureRecognizer(tapRecognizer!)
    }
}
