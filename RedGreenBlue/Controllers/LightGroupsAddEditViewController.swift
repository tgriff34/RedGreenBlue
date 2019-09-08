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

    var group: RGBGroup!
    var lights = [Light]()
    var swiftyHue: SwiftyHue!

    var selectedLights: [String] = []
    var name: String = ""
    var userEditing: Bool = false

    var onSave: ((Bool) -> Void)?

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var textField: UITextField!

    var tapRecogniser: UITapGestureRecognizer?

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

        tapRecogniser = UITapGestureRecognizer()
        tapRecogniser?.addTarget(self, action: #selector(viewTapped))

        fetchData()
    }

    func save() {
        dismiss(animated: true, completion: nil)
        if userEditing {
            onSave?(false)
        } else {
            onSave?(true)
        }
    }

    @objc func viewTapped() {
        self.view.endEditing(true)
    }

    @objc func cancel() {
        dismiss(animated: true, completion: nil)
    }

    @objc func add() {
        if userEditing {
            guard let group = group else {
                logger.error("did not receive editing group")
                return
            }
            swiftyHue.bridgeSendAPI.updateGroupWithId(group.identifier, newName: name,
                                                       newLightIdentifiers: selectedLights,
                                                       completionHandler: { _ in
                                                        self.save()
            })
        } else {
            swiftyHue.bridgeSendAPI.createGroupWithName(name, andType: .LightGroup,
                                                         includeLightIds: selectedLights,
                                                         completionHandler: { _ in
                                                            self.save()
            })
        }
    }

    func enableOrDisableSaveButton() {
        if selectedLights.isEmpty || textField.text?.isEmpty ?? false {
            navigationItem.rightBarButtonItem?.isEnabled = false
        } else {
            navigationItem.rightBarButtonItem?.isEnabled = true
        }
    }

    func fetchData() {
        RGBRequest.shared.getLights(with: self.swiftyHue, completion: { (lights) in
            self.lights = Array(lights.values).map({ return $0 })
            self.lights.sort(by: { $0.identifier < $1.identifier })
            self.tableView.reloadData()
        })
    }
}

// MARK: - TableView
extension LightGroupsAddEditViewController {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return lights.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SelectedLightIdentifier", for: indexPath)

        cell.textLabel?.text = lights[indexPath.row].name

        if selectedLights.contains(lights[indexPath.row].identifier) {
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        } else {
            cell.accessoryType = .none
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.accessoryType = .checkmark
        selectedLights.append(lights[indexPath.row].identifier)
        enableOrDisableSaveButton()
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.accessoryType = .none
        selectedLights.remove(at: selectedLights.index(of: lights[indexPath.row].identifier)!)
        enableOrDisableSaveButton()
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
        self.view.removeGestureRecognizer(tapRecogniser!)
        enableOrDisableSaveButton()
    }
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.view.addGestureRecognizer(tapRecogniser!)
    }
}
