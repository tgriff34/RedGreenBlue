//
//  DynamicScenesAddTimeViewController.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 9/25/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import UIKit

class DynamicScenesAddTimeViewController: UITableViewController {

    weak var addTimeDelegate: DynamicSceneAddTimeDelegate?

    var type: TimeType?
    var selectedTime: Int?

    var timeArray: [Int: Int] = [1: 0, 3: 1, 5: 2, 10: 3]

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let indexPath = IndexPath(row: timeArray[selectedTime!]!, section: 0)
        self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        self.tableView(self.tableView, didSelectRowAt: indexPath)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath),
            let text = cell.textLabel?.text {

            let subString = text.split(separator: " ")
            guard let number = Int(subString[0]) else {
                return
            }
            cell.accessoryType = .checkmark
            addTimeDelegate?.dynamicSceneTimeAdded(type!, number)
        }
    }

    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = .none
        }
    }
}
