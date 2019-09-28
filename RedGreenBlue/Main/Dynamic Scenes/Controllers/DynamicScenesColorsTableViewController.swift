//
//  DynamicScenesColorsTableViewController.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 9/25/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import UIKit
import RealmSwift

class DynamicScenesColorsTableViewController: UITableViewController {
    var colors = List<XYColor>()
    weak var addColorsDelegate: DynamicSceneAddAllColorsDelegate?
}

// MARK: - TableView
extension DynamicScenesColorsTableViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return colors.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "colorCell")!
        cell.textLabel?.text = "\(colors[indexPath.row].xvalue), \(colors[indexPath.row].yvalue)"
        return cell
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle,
                            forRowAt indexPath: IndexPath) {
        switch editingStyle {
        case .delete:
            colors.remove(at: indexPath.row)
            tableView.beginUpdates()
            tableView.deleteRows(at: [indexPath], with: .automatic)
            tableView.endUpdates()
            addColorsDelegate?.dynamicSceneColorsAdded(colors)
        default:
            logger.error("Editing style is non existant: \(editingStyle)")
        }
    }
}

// MARK: - Navigation
extension DynamicScenesColorsTableViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "addColorSegue":
            let viewController = segue.destination as? DynamicScenesAddColorViewController
            viewController?.color = nil
            viewController?.addColorDelegate = self
        case "EditingColorSegue":
            let viewController = segue.destination as? DynamicScenesAddColorViewController
            let row = self.tableView.indexPathForSelectedRow?.row
            viewController?.color = colors[row!]
            viewController?.addColorDelegate = self
        default:
            logger.error("No such segue identifier: \(String(describing: segue.identifier))")
        }
    }
}

// MARK: - Delegate
extension DynamicScenesColorsTableViewController: DynamicSceneAddColorDelegate {
    func dynamicSceneColorAdded(_ color: XYColor) {
        tableView.beginUpdates()
        if let row = self.tableView.indexPathForSelectedRow?.row {
            colors[row] = color
            tableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .none)
        } else {
            colors.append(color)
            tableView.insertRows(at: [IndexPath(row: colors.count - 1, section: 0)], with: .automatic)
        }
        addColorsDelegate?.dynamicSceneColorsAdded(colors)
        tableView.endUpdates()
    }
}
