//
//  SettingsViewController.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 10/1/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import UIKit
import SwiftyHue
import MessageUI

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
                self.allGroupNames = ["Default"] + groups.flatMap({ $0 }).map({ $0.name })
                self.roomGroupNames = ["Default"] + groups.flatMap({ $0 })
                    .filter({ $0.type == GroupType.Room }).map({ $0.name })
            }
        })
        tableView.reloadData()
    }

    private func createActionSheetForOption(title: String?, message: String?, style: UIAlertController.Style,
                                            options: [String], forKey: String) {
        var checkedIndex: Int = 0
        let indexPath = self.tableView.indexPathForSelectedRow!
        let actionSheet = UIAlertController(title: title, message: message, preferredStyle: style)

        for (index, option) in options.enumerated() {
            let newAction = UIAlertAction(title: option, style: .default, handler: { _ in
                UserDefaults.standard.set(option, forKey: forKey)
                self.tableView.reloadRows(at: [indexPath], with: .none)
                actionSheet.actions[index].setValue(true, forKey: "checked")
                actionSheet.actions[checkedIndex].setValue(false, forKey: "checked")
            })
            if let key = UserDefaults.standard.object(forKey: forKey) as? String, key == option {
                newAction.setValue(true, forKey: "checked")
                checkedIndex = index
            }
            actionSheet.addAction(newAction)
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        actionSheet.addAction(cancelAction)
        self.present(actionSheet, animated: true, completion: nil)
    }

    private func composeEmail() {
        if MFMailComposeViewController.canSendMail() {
            console.debug("can send")
            let mailComposer = MFMailComposeViewController()
            mailComposer.setSubject("Crash Logs")
            mailComposer.setMessageBody("Here are my crash logs!", isHTML: false)
            // TODO: Change Recipient
            mailComposer.setToRecipients(["tjg22596@gmail.com"])
            mailComposer.mailComposeDelegate = self
            guard let filePath = UserDefaults.standard.url(forKey: "LogFile") else {
                return
            }
            do {
                let attachmentData = try Data(contentsOf: filePath)
                mailComposer.addAttachmentData(attachmentData, mimeType: "application/log", fileName: "swiftybeaver")
                self.present(mailComposer, animated: true, completion: nil)
            } catch {
                console.debug("Encountered Error")
            }
        }
    }
}

// MARK: - TableView
extension SettingsTableViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        if #available(iOS 13, *) {
            return 3
        }
        return 2
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        switch indexPath.section {
        case 0:
            if indexPath.row == 1 {
                cell.detailTextLabel?.text = UserDefaults.standard.object(forKey: "DefaultScene") as? String
            } else if indexPath.row == 2 {
                cell.detailTextLabel?.text = UserDefaults.standard.object(forKey: "DefaultCustomScene") as? String
            } else if indexPath.row == 3 {
                cell.detailTextLabel?.text = UserDefaults.standard.object(forKey: "SoundSetting") as? String
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
                let message = String(format: "%@%@", "This is the group that will be automatically",
                                     " selected when changing to the scenes tab.")
                createActionSheetForOption(title: "Change default group",
                                           message: message,
                                           style: .actionSheet,
                                           options: roomGroupNames, forKey: "DefaultScene")
            } else if indexPath.row == 2 {
                let message = String(format: "%@%@", "This is the group that will be automatically",
                                     " selected when changing to the custom scenes tab.")
                createActionSheetForOption(title: "Change default group",
                                           message: message,
                                           style: .actionSheet,
                                           options: allGroupNames, forKey: "DefaultCustomScene")
            } else if indexPath.row == 3 {
                createActionSheetForOption(title: nil,
                                           message: nil,
                                           style: .actionSheet,
                                           options: ["Unmuted", "Muted"], forKey: "SoundSetting")
            }
        case 1:
            composeEmail()
        default:
            break
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - Mail Delegate
extension SettingsTableViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult, error: Error?) {
        switch result {
        case .sent:
            controller.dismiss(animated: true, completion: {
                let alert = UIAlertController(
                    title: "Sent",
                    message: String(format: "%@%@", "Thank you for sending your crash",
                                    " logs and making RedGreenBlue a better app!"),
                    preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            })
        case .failed:
            controller.dismiss(animated: true, completion: {
                let alert = UIAlertController(
                    title: "Error",
                    message: "An error occured while trying to send the log files.",
                    preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            })
        default:
            controller.dismiss(animated: true, completion: nil)
        }
    }
}
