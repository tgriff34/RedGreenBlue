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

    var swiftyHue: SwiftyHue!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        swiftyHue = RGBRequest.shared.getSwiftyHue()
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
        } else {
            let alert = UIAlertController(
                title: "Cannot send email",
                message: "This device is not able to send email.",
                preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
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
