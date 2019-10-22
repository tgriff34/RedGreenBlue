//
//  DSAddSoundVC.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 10/4/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import UIKit

class DynamicScenesAddSoundViewController: UITableViewController {
    weak var addSoundFileDelegate: DynamicSceneAddSoundFileDelegate?

    var selectedSoundFile: String?

    let soundFiles: [String] = ["FeelinGood", "test"]

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        var indexPath: IndexPath?
        if selectedSoundFile == "Default" {
            indexPath = IndexPath(row: 0, section: 0)
        } else {
            indexPath = IndexPath(row: soundFiles.firstIndex(of: selectedSoundFile!) ?? 0, section: 1)
        }
        self.tableView.selectRow(at: indexPath!, animated: true, scrollPosition: .none)
        self.tableView(self.tableView, didSelectRowAt: indexPath!)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SoundFileCell")!
        switch indexPath.section {
        case 0:
            cell.textLabel?.text = "Default"
        case 1:
            cell.textLabel?.text = soundFiles[indexPath.row]
        default:
            break
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath),
            let text = cell.textLabel?.text {
            cell.accessoryType = .checkmark
            addSoundFileDelegate?.dynamicSceneSoundFileAdded(text)
        }
    }

    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = .none
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        return soundFiles.count
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
}
