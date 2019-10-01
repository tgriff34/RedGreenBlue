//
//  ThemeTableViewController.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 10/1/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import UIKit

class ThemeTableViewController: UITableViewController {
    @IBOutlet weak var systemDarkModeSwitch: UISwitch!

    override func viewDidLoad() {
        super.viewDidLoad()

        systemDarkModeSwitch.addTarget(self, action: #selector(systemDarkModeDidChange(_:)), for: .valueChanged)

        switch UserDefaults.standard.object(forKey: "AppTheme") as? String {
        case "dark":
            systemDarkModeSwitch.setOn(false, animated: true)
            tableView.selectRow(at: IndexPath(row: 0, section: 1), animated: true, scrollPosition: .none)
            self.tableView(self.tableView, didSelectRowAt: IndexPath(row: 0, section: 1))
        case "light":
            systemDarkModeSwitch.setOn(false, animated: true)
            tableView.selectRow(at: IndexPath(row: 1, section: 1), animated: true, scrollPosition: .none)
            self.tableView(self.tableView, didSelectRowAt: IndexPath(row: 1, section: 1))
        case "system":
            systemDarkModeSwitch.setOn(true, animated: true)
        default:
            logger.error("Error AppTheme is nil")
        }
        tableView.reloadData()
    }

    @objc func systemDarkModeDidChange(_ sender: UISwitch) {
        tableView.reloadSections(IndexSet(arrayLiteral: 1), with: .automatic)
        tableView.deselectRow(at: IndexPath(row: 1, section: 1), animated: true)
        self.tableView(self.tableView, didDeselectRowAt: IndexPath(row: 1, section: 1))
        if sender.isOn {
            UserDefaults.standard.set("system", forKey: "AppTheme")
            if #available(iOS 13.0, *) {
                tabBarController?.overrideUserInterfaceStyle = UIScreen.main.traitCollection.userInterfaceStyle
            }
        } else {
            tableView.selectRow(at: IndexPath(row: 0, section: 1), animated: true, scrollPosition: .none)
            self.tableView(self.tableView, didSelectRowAt: IndexPath(row: 0, section: 1))
        }
    }
}

extension ThemeTableViewController {
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 1 {
            if systemDarkModeSwitch.isOn {
                return 0.1
            }
        }
        return super.tableView(tableView, heightForFooterInSection: section)
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 1 {
            if systemDarkModeSwitch.isOn {
                return 0.1
            }
        }
        return super.tableView(tableView, heightForHeaderInSection: section)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 {
            if systemDarkModeSwitch.isOn {
                return 0
            } else {
                return 2
            }
        }
        return super.tableView(tableView, numberOfRowsInSection: section)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        switch indexPath.section {
        case 1:
            if UserDefaults.standard.object(forKey: "AppTheme") as? String == "dark" && indexPath.row == 0 {
                tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            } else if UserDefaults.standard.object(forKey: "AppTheme") as? String == "light" && indexPath.row == 1 {
                tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            }
        default:
            break
        }
        return cell
    }
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if indexPath.section == 0 {
            return nil
        }
        return indexPath
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 1:
            let cell = tableView.cellForRow(at: indexPath)
            cell?.accessoryType = .checkmark

            if indexPath.row == 0  && !systemDarkModeSwitch.isOn {
                if #available(iOS 13.0, *) {
                    tabBarController?.overrideUserInterfaceStyle = .dark
                    UserDefaults.standard.set("dark", forKey: "AppTheme")
                }
            } else if !systemDarkModeSwitch.isOn {
                if #available(iOS 13.0, *) {
                    tabBarController?.overrideUserInterfaceStyle = .light
                    UserDefaults.standard.set("light", forKey: "AppTheme")
                }
            }
        default:
            break
        }
    }
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.accessoryType = .none
    }
}
