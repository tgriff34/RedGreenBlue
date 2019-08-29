//
//  LightGroupsAddEditViewController.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 8/24/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import UIKit
import SwiftyHue

class LightGroupsAddEditViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var group: Group?
    var groupIdentifiers: [String]?
    var lights: [String: Light]?
    var lightIdentifiers: [String]?
    var swiftyHue: SwiftyHue?

    var selectedLights: [String] = []
    var name: String = ""
    var userEditing: Bool = false

    var onSave: ((Bool) -> Void)?

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var textField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel,
                                                           target: self, action: #selector(cancel))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save,
                                                            target: self, action: #selector(add))

        if selectedLights.isEmpty {
            navigationItem.title = "Add Group"
            navigationItem.rightBarButtonItem?.isEnabled = false
        } else {
            userEditing = true
            navigationItem.title = "Edit Group"
            navigationItem.rightBarButtonItem?.isEnabled = true
        }

        textField.text = name
        textField.delegate = self
        tableView.delegate = self
        tableView.dataSource = self

        guard let lights = lights else {
            return
        }

        lightIdentifiers = RGBGroupsAndLightsHelper.retrieveLightIds(from: lights)
    }

    func save() {
        dismiss(animated: true, completion: nil)
        if userEditing {
            onSave?(false)
        } else {
            onSave?(true)
        }
    }

    @objc func cancel() {
        dismiss(animated: true, completion: nil)
    }

    @objc func add() {
        if userEditing {
            guard let group = group else {
                print("Error did not receive editing group")
                return
            }
            swiftyHue?.bridgeSendAPI.updateGroupWithId(group.identifier, newName: name,
                                                       newLightIdentifiers: selectedLights,
                                                       completionHandler: { _ in
                                                        self.save()
            })
        } else {
            swiftyHue?.bridgeSendAPI.createGroupWithName(name, andType: .LightGroup,
                                                         includeLightIds: selectedLights,
                                                         completionHandler: { _ in
                                                            self.save()
            })
        }
    }

    func enableOrDisableSaveButton() {
        if selectedLights.isEmpty || textField.text?.isEmpty ?? true {
            navigationItem.rightBarButtonItem?.isEnabled = false
        } else {
            navigationItem.rightBarButtonItem?.isEnabled = true
        }
    }
}

// MARK: - TableView
extension LightGroupsAddEditViewController {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let lights = lights else {
            return 0
        }
        return lights.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SelectedLightIdentifier", for: indexPath)

        guard let light = lights?[lightIdentifiers![indexPath.row]] else {
            print("Error could not receive light for: ", indexPath.row)
            return cell
        }

        cell.textLabel?.text = light.name

        if selectedLights.contains(light.identifier) {
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        } else {
            cell.accessoryType = .none
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.accessoryType = .checkmark
        selectedLights.append(lightIdentifiers![indexPath.row])
        enableOrDisableSaveButton()
        print(selectedLights)
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.accessoryType = .none
        selectedLights.remove(at: selectedLights.index(of: lightIdentifiers![indexPath.row])!)
        enableOrDisableSaveButton()
        print(selectedLights)
    }
}

// MARK: - TextField Delegate
extension LightGroupsAddEditViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        name = textField.text ?? ""
        enableOrDisableSaveButton()
    }
}
