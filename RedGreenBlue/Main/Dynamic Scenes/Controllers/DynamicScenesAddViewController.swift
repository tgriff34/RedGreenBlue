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

    var colors = List<XYColor>()
    var time: Int = 1
    var name: String = ""

    var tapRecognizer: UITapGestureRecognizer?

    weak var addSceneDelegate: DynamicSceneAddDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel,
                                                           target: self, action: #selector(cancel))

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save,
                                                            target: self, action: #selector(save))

        navigationItem.rightBarButtonItem?.isEnabled = false

        textField.delegate = self
        tapRecognizer = UITapGestureRecognizer()
        tapRecognizer?.addTarget(self, action: #selector(viewTapped))
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
                                    randomColors: randomColorsSwitch.isOn)
        scene.xys = self.colors
        addSceneDelegate?.dynamicSceneAdded(self, scene)
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
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            break
        case 1:
            let cell = tableView.cellForRow(at: indexPath)
            if indexPath.row == 0 {
                if time == 1 {
                    cell?.detailTextLabel!.text = "\(time) second"
                } else {
                    cell?.detailTextLabel!.text = "\(time) seconds"
                }
            } else if indexPath.row == 1 {
                cell?.detailTextLabel?.text = "\(colors.count) colors"
            }
        default:
            logger.error("No section for \(indexPath.section)")
        }
        return super.tableView(tableView, cellForRowAt: indexPath)
    }
}

// MARK: - Navigation / Set Delegate to self
extension DynamicScenesAddViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "colorsSegue":
            let viewController = segue.destination as? DynamicScenesColorsTableViewController
            viewController?.colors = colors
            viewController?.addColorsDelegate = self
        case "timeBetweenChangingSegue":
            let viewController = segue.destination as? DynamicScenesAddTimeViewController
            viewController?.addTimeDelegate = self
            viewController?.selectedTime = time
        default:
            logger.error("segue identifier does not exist: \(segue.identifier ?? "nil")")
        }
    }
}

// MARK: - Add Color / Time Delegate
extension DynamicScenesAddViewController: DynamicSceneAddAllColorsDelegate, DynamicSceneAddTimeDelegate {
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
