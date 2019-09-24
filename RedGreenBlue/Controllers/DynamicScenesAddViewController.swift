//
//  DynamicScenesAddViewController.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 9/24/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import UIKit
import RealmSwift

class DynamicScenesAddViewController: UIViewController {
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var pickerView: UIPickerView!

    var pickerData = [Int]()
    var colors = List<XYColor>()
    var name: String = ""

    var tapRecognizer: UITapGestureRecognizer?

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel,
                                                           target: self, action: #selector(cancel))

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save,
                                                            target: self, action: #selector(save))

        pickerData = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]
        pickerView.delegate = self
        pickerView.dataSource = self
        tableView.delegate = self
        tableView.dataSource = self
        textField.delegate = self
        textField.text = name

        tapRecognizer = UITapGestureRecognizer()
        tapRecognizer?.addTarget(self, action: #selector(viewTapped))
    }

    @objc func viewTapped() {
        self.view.endEditing(true)
    }

    @objc func save() {
        let realm = RGBDatabaseManager.realm()!
        dismiss(animated: true, completion: {
            let scene = RGBDynamicScene(name: self.name,
                                        timer: Double(self.pickerView.selectedRow(inComponent: 0)),
                                        brightnessDifference: 0)
            scene.xys = self.colors
            RGBDatabaseManager.write(to: realm, closure: {
                realm.add(scene)
            })
        })
    }

    @objc func cancel() {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - PickerView
extension DynamicScenesAddViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }

    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int,
                    forComponent component: Int) -> NSAttributedString? {
        let string = "\(pickerData[row]) seconds"
        return NSAttributedString(string: string, attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
    }
}

// MARK: - TableView
extension DynamicScenesAddViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return colors.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "colorCell")!
        cell.textLabel?.text = "\(colors[indexPath.row].xvalue), \(colors[indexPath.row].yvalue)"
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        switch editingStyle {
        case .delete:
            colors.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        default:
            logger.error("editing style does not exist: \(editingStyle)")
            break
        }
    }
}

// MARK: - Text Field Delegate
extension DynamicScenesAddViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        name = textField.text ?? ""
        self.view.removeGestureRecognizer(tapRecognizer!)
    }
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.view.addGestureRecognizer(tapRecognizer!)
    }
}

// MARK: - Navigation / Set Delegate to self
extension DynamicScenesAddViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "addColorSegue":
            let viewController = segue.destination as? DynamicScenesAddColorViewController
            viewController?.addColorDelegate = self
        default:
            logger.error("segue identifier does not exist: \(segue.identifier ?? "nil")")
            break
        }
    }
}

// MARK: - Add Color Delegate
extension DynamicScenesAddViewController: DynamicSceneAddColorDelegate {
    func dynamicSceneColorAdded(_ color: XYColor) {
        self.colors.append(color)
        tableView.reloadData()
    }
}
