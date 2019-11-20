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

    var dismissKeyboardGesture: UITapGestureRecognizer?

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
    var fluctuatingBrightness: Bool = true
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
        dismissKeyboardGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))

        // If the user is editing a scene, set the variables to scene values
        setSceneIfEditing()
    }

    @objc func viewTapped() {
        self.view.endEditing(true)
    }

    @objc func save() {
        // Create new scene to populate DB with
        let scene = RGBDynamicScene(
            name: self.name, timer: Double(time), category: .custom,
            lightsChangeColor: lightsChangeColor,
            displayMultipleColors: multiColors,
            sequentialLightChange: shiftRight,
            randomColors: randomColors, soundFile: soundFileName,
            isBrightnessEnabled: fluctuatingBrightness, brightnessTimer: Double(brightnessTime),
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
            fluctuatingBrightness = scene.isBrightnessEnabled
            brightnessTime = Int(scene.brightnessTimer)
            minBrightness = scene.minBrightness
            maxBrightness = scene.maxBrightness
            tableView.reloadRows(at: [IndexPath(row: 0, section: 1), IndexPath(row: 1, section: 1),
                                      IndexPath(row: 0, section: 2), IndexPath(row: 0, section: 3)],
                                 with: .none)
        }
    }

    private func enableOrDisableSaveButton(_ indexPath: IndexPath, _ cell: UITableViewCell? = nil) {
        var useCell: UITableViewCell?
        if cell != nil {
            useCell = cell
        } else {
            useCell = tableView.cellForRow(at: indexPath)
        }

        switch indexPath.section {
        case 0:
            if textField.text?.isEmpty ?? false {
                useCell?.accessoryType = .detailButton
            } else {
                useCell?.accessoryType = .none
            }
        case 1:
            if colors.isEmpty {
                useCell?.accessoryType = .detailDisclosureButton
            } else {
                useCell?.accessoryType = .disclosureIndicator
            }
        default:
            return
        }

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
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        if indexPath.section == 0 && indexPath.row == 0 {
            performSegue(withIdentifier: "popoverSegue", sender: tableView.cellForRow(at: indexPath)!.accessoryView)
        } else if indexPath.section == 1 && indexPath.row == 0 {
            performSegue(withIdentifier: "popoverSegue", sender: tableView.cellForRow(at: indexPath)!.accessoryView)
        }
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        switch indexPath.section {
        case 0:
            textField.text = name
            enableOrDisableSaveButton(indexPath, cell)
        case 1:
            if indexPath.row == 0 {
                cell.detailTextLabel?.text = colors.count > 1 ? "\(colors.count) colors" : "\(colors.count) color"
                enableOrDisableSaveButton(indexPath, cell)
            } else if indexPath.row == 1 {
                cell.detailTextLabel?.text = lightsChangeColor ? "On" : "Off"
            }
        case 2:
            if indexPath.row == 0 {
                cell.detailTextLabel?.text = fluctuatingBrightness ? "On" : "Off"
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
        case "ChangingLightColorsSegue":
            let viewController = segue.destination as? DynamicScenesColorOptionsViewController
            viewController?.colorOptionsDelegate = self
            viewController?.lightsChangeColor =  lightsChangeColor
            viewController?.displayMultiColors = multiColors
            viewController?.randomColors = randomColors
            viewController?.shiftRight = shiftRight
            viewController?.time = time
        case "ShowBrightnessOptionsSegue":
            let viewController = segue.destination as?  DynamicScenesBrightnessOptionsViewController
            viewController?.brightnessOptionsDelegate = self
            viewController?.fluctuatingBrightness = fluctuatingBrightness
            viewController?.minBrightness = minBrightness
            viewController?.maxBrightness = maxBrightness
            viewController?.brightnessTime = brightnessTime
        case "SoundFileSegue":
            let viewController = segue.destination as? DynamicScenesAddSoundViewController
            viewController?.addSoundFileDelegate = self
            viewController?.selectedSoundFile = soundFileName
        case "popoverSegue":
            let popoverViewController = segue.destination
            popoverViewController.modalPresentationStyle = .popover
            popoverViewController.popoverPresentationController?.delegate = self
        default:
            logger.error("segue identifier does not exist: \(segue.identifier ?? "nil")")
        }
    }
}

// MARK: - Popover delegate
extension DynamicScenesAddViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}

// MARK: - Add Color / Time Delegate
extension DynamicScenesAddViewController: DynamicSceneAddAllColorsDelegate, DynamicSceneAddSoundFileDelegate,
DynamicSceneColorOptionsDelegate, DynamicSceneBrightnessOptionsDelegate {
    func minMaxBrightnessValues(_ min: Int, _ max: Int) {
        self.minBrightness = min
        self.maxBrightness = max
    }

    func fluctuatingBrightnessEnabled(_ value: Bool) {
        self.fluctuatingBrightness = value
        tableView.reloadRows(at: [IndexPath(row: 0, section: 2)], with: .none)
    }

    func lightsChangeColor(_ value: Bool) {
        self.lightsChangeColor = value
        tableView.reloadRows(at: [IndexPath(row: 1, section: 1)], with: .none)
    }

    func timeBetweenCycle(_ type: TimeType, _ time: Int) {
        switch type {
        case .brightness:
            self.brightnessTime = time
        case .color:
            self.time = time
        }
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
        tableView.reloadRows(at: [IndexPath(row: 0, section: 3)], with: .none)
    }

    func dynamicSceneColorsAdded(_ colors: List<XYColor>) {
        self.colors = colors
        tableView.reloadRows(at: [IndexPath(row: 0, section: 1)], with: .none)
        enableOrDisableSaveButton(IndexPath(row: 0, section: 1))
    }
}

// MARK: - TextField Delegate
extension DynamicScenesAddViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        view.removeGestureRecognizer(dismissKeyboardGesture!)
    }
    func textFieldDidBeginEditing(_ textField: UITextField) {
        view.addGestureRecognizer(dismissKeyboardGesture!)
    }
    @objc func textFieldDidChange(_ textField: UITextField) {
        self.name = textField.text ?? ""
        enableOrDisableSaveButton(IndexPath(row: 0, section: 0))
    }
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
