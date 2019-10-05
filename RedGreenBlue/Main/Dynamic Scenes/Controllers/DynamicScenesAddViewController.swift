//
//  DynamicScenesAddViewController.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 9/24/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import UIKit
import RealmSwift

class DynamicScenesAddViewController: UITableViewController {

    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var sequentialLightChangeSwitch: UISwitch!
    @IBOutlet weak var randomColorsSwitch: UISwitch!

    var scene: RGBDynamicScene?
    var colors = List<XYColor>()
    var time: Int = 1
    var name: String = ""
    var soundFileName: String = "Default"

    var tapRecognizer: UITapGestureRecognizer?

    weak var addSceneDelegate: DynamicSceneAddDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel,
                                                           target: self, action: #selector(cancel))

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save,
                                                            target: self, action: #selector(save))

        textField.delegate = self
        tapRecognizer = UITapGestureRecognizer()
        tapRecognizer?.addTarget(self, action: #selector(viewTapped))

        if let scene = scene {
            for color in scene.xys { // needs to copy instead of assigning as reference
                colors.append(XYColor([color.xvalue, color.yvalue]))
            }
            time = Int(scene.timer)
            name = String(scene.name)
            sequentialLightChangeSwitch.isOn = scene.sequentialLightChange
            randomColorsSwitch.isOn = scene.randomColors
            soundFileName = scene.soundFile
            tableView.reloadRows(at: [IndexPath(row: 0, section: 1),
                                      IndexPath(row: 1, section: 1),
                                      IndexPath(row: 0, section: 2)],
                                 with: .none)
        }
    }

    @objc func viewTapped() {
        self.view.endEditing(true)
    }

    @objc func save() {
        let scene = RGBDynamicScene(name: self.name,
                                    timer: Double(time),
                                    brightnessDifference: 0,
                                    isDefault: false,
                                    sequentialLightChange: sequentialLightChangeSwitch.isOn,
                                    randomColors: randomColorsSwitch.isOn, soundFile: soundFileName)
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
            return 3
        }
        return 4
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            textField.text = name
            enableOrDisableSaveButton()
        case 1:
            let cell = super.tableView(tableView, cellForRowAt: indexPath)
            if indexPath.row == 0 {
                if time == 1 {
                    cell.detailTextLabel!.text = "\(time) second"
                } else {
                    cell.detailTextLabel!.text = "\(time) seconds"
                }
            } else if indexPath.row == 1 {
                cell.detailTextLabel?.text = "\(colors.count) colors"
            }
            return cell
        case 2:
            let cell = super.tableView(tableView, cellForRowAt: indexPath)
            cell.detailTextLabel?.text = soundFileName
        case 3:
            break
        default:
            logger.error("No section for \(indexPath.section)")
        }
        return super.tableView(tableView, cellForRowAt: indexPath)
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 3 {
            let actionSheet = UIAlertController(title: "Delete Scene",
                                                message: "Are you sure you want to delete this scene?",
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
        case "colorsSegue":
            let viewController = segue.destination as? DynamicScenesColorsCollectionViewController
            viewController?.colors = colors
            viewController?.addColorsDelegate = self
        case "timeBetweenChangingSegue":
            let viewController = segue.destination as? DynamicScenesAddTimeViewController
            viewController?.addTimeDelegate = self
            viewController?.selectedTime = time
        case "soundFileSegue":
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
        tableView.reloadRows(at: [IndexPath(row: 0, section: 2)], with: .none)
    }

    func dynamicSceneColorsAdded(_ colors: List<XYColor>) {
        self.colors = colors
        tableView.reloadRows(at: [IndexPath(row: 1, section: 1)], with: .none)
        enableOrDisableSaveButton()
    }

    func dynamicSceneTimeAdded(_ time: Int) {
        self.time = time
        tableView.reloadRows(at: [IndexPath(row: 0, section: 1)], with: .none)
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
