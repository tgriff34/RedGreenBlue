//
//  LightGroupsAddEditViewController.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 8/24/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import UIKit
import SwiftyHue

class LightGroupsAddEditViewController: UITableViewController {

    var group: RGBGroup!
    var lights = [Light]()
    var swiftyHue: SwiftyHue!

    var selectedLights = [String]()
    var name: String = ""

    weak var addGroupDelegate: GroupAddDelegate?

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
            navigationItem.title = "Edit Group"
            navigationItem.rightBarButtonItem?.isEnabled = true
        }

        fetchData()
    }

    @objc func viewTapped() {
        self.view.endEditing(true)
    }

    @objc func cancel() {
        dismiss(animated: true, completion: nil)
    }

    @objc func add() {
        addGroupDelegate?.groupAddedSuccess(name, selectedLights)
        dismiss(animated: true, completion: nil)
    }

    private func enableOrDisableSaveButton() {
        let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? LightsGroupAddNameCell
        if selectedLights.isEmpty || cell?.textField.text?.isEmpty ?? false {
            navigationItem.rightBarButtonItem?.isEnabled = false
        } else {
            navigationItem.rightBarButtonItem?.isEnabled = true
        }
    }

    private func fetchData() {
        RGBRequest.shared.getLights(with: self.swiftyHue, completion: { (lights) in
            self.lights = Array(lights.values).map({ return $0 })
            self.lights.sort(by: { $0.identifier < $1.identifier })
            self.tableView.reloadData()
        })
    }
}

// MARK: - TableView
extension LightGroupsAddEditViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        return lights.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            //swiftlint:disable:next force_cast
            let cell = tableView.dequeueReusableCell(withIdentifier: "textFieldCell") as! LightsGroupAddNameCell
            cell.textField.delegate = self
            cell.textField.text = name
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SelectedLightIdentifier")!

            cell.textLabel?.text = lights[indexPath.row].name

            if selectedLights.contains(lights[indexPath.row].identifier) {
                self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
            return cell
        default:
            logger.error("No section exists for: \(indexPath.section)")
            return super.tableView(tableView, cellForRowAt: indexPath)
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1, let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = .checkmark
            selectedLights.append(lights[indexPath.row].identifier)
            enableOrDisableSaveButton()
        }
    }

    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if indexPath.section == 1, let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = .none
            selectedLights.remove(at: selectedLights.index(of: lights[indexPath.row].identifier)!)
            enableOrDisableSaveButton()
        }
    }
}

// MARK: - TextField Delegate
extension LightGroupsAddEditViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    func textFieldDidChangeSelection(_ textField: UITextField) {
        name = textField.text ?? ""
        enableOrDisableSaveButton()
    }
}
