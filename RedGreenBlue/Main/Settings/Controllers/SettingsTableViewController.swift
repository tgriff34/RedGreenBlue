//
//  SettingsViewController.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 10/1/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import UIKit
import SwiftyHue

class SettingsTableViewController: UITableViewController {

    var allGroupNames = [String]()
    var roomGroupNames = [String]()
    var swiftyHue: SwiftyHue!

    override func viewDidLoad() {
        super.viewDidLoad()
        swiftyHue = RGBRequest.shared.getSwiftyHue()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        RGBRequest.shared.getGroups(with: swiftyHue, completion: { (groups, _) in
            if let groups = groups {
                self.allGroupNames = groups.flatMap({ $0 }).map({ $0.name })
                self.roomGroupNames = groups.flatMap({ $0 }).filter({ $0.type == GroupType.Room }).map({ $0.name })
            }
        })
        tableView.reloadData()
    }

    /*
       TODO: Potentially useful for more DRY approach
             Might be difficult since others would have unique handlers for actions.
    */
    private func createActionSheetForOption(title: String?, message: String?, style: UIAlertController.Style,
                                            options: [String], forKey: String) {
        let indexPath = self.tableView.indexPathForSelectedRow!
        let actionSheet = UIAlertController(title: title,
                                            message: message,
                                            preferredStyle: style)
        let defaultAction = UIAlertAction(title: "Default", style: .default, handler: { _ in
            UserDefaults.standard.set("Default", forKey: forKey)
            self.tableView.reloadRows(at: [indexPath], with: .none)
        })
        actionSheet.addAction(defaultAction)

        for option in options {
            let newAction = UIAlertAction(title: option, style: .default, handler: { _ in
                UserDefaults.standard.set(option, forKey: forKey)
                self.tableView.reloadRows(at: [indexPath], with: .none)
            })
            actionSheet.addAction(newAction)
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        actionSheet.addAction(cancelAction)
        self.present(actionSheet, animated: true, completion: nil)
    }
}

extension SettingsTableViewController {
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        switch indexPath.section {
        case 0:
            if indexPath.row == 1 {
                cell.detailTextLabel?.text = UserDefaults.standard.object(forKey: "DefaultScene") as? String
            } else if indexPath.row == 2 {
                cell.detailTextLabel?.text = UserDefaults.standard.object(forKey: "DefaultCustomScene") as? String
            }
        default:
            break
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            if indexPath.row == 1 {
                createActionSheetForOption(title: nil, message: nil, style: .actionSheet,
                                           options: roomGroupNames, forKey: "DefaultScene")
            } else if indexPath.row == 2 {
                createActionSheetForOption(title: nil, message: nil, style: .actionSheet,
                                           options: allGroupNames, forKey: "DefaultCustomScene")
            }
        default:
            break
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
