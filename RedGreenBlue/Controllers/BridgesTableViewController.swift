//
//  BridgesTableViewController.swift
//  RedGreenBlue
//
//  Created by Dana Griffin on 8/15/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import UIKit
import SwiftyHue
import RealmSwift
import SwiftMessages

class BridgesTableViewController: UITableViewController {

    var bridgeFinder = BridgeFinder()
    var bridges = [RGBHueBridge]()
    var authorizedBridges = [RGBHueBridge]()
    var selectedBridge: RGBHueBridge?
    var bridgeAuthenticator: BridgeAuthenticator?
    let realm: Realm? = RGBDatabaseManager.realm()

    // swiftlint:disable:next force_try
    let linkBridgeMessageAlert: MessageView = try! SwiftMessages.viewFromNib(named: "CustomMessageView")
    let linkFailMessageAlert = MessageView.viewFromNib(layout: .cardView)
    var warningAlertConfig = SwiftMessages.Config()
    var errorAlertConfig = SwiftMessages.Config()

    override func viewDidLoad() {
        super.viewDidLoad()

        // set up warning message card
        warningAlertConfig.duration = .forever
        linkBridgeMessageAlert.configureTheme(.warning)
        warningAlertConfig.dimMode = .gray(interactive: false)
        warningAlertConfig.interactiveHide = false
        linkBridgeMessageAlert.configureDropShadow()
        linkBridgeMessageAlert.configureContent(title: "", body: "Please press the button on your bridge to link")
        linkBridgeMessageAlert.layoutMarginAdditions = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        linkBridgeMessageAlert.button?.isHidden = true
        (linkBridgeMessageAlert.backgroundView as? CornerRoundingView)?.cornerRadius = 10

        // set up error message card
        errorAlertConfig.duration = .forever
        errorAlertConfig.dimMode = .gray(interactive: true)
        linkFailMessageAlert.configureTheme(.error)
        linkFailMessageAlert.configureDropShadow()
        linkFailMessageAlert.layoutMarginAdditions = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        linkFailMessageAlert.button?.isHidden = true
        (linkFailMessageAlert.backgroundView as? CornerRoundingView)?.cornerRadius = 10
    }

    override func viewWillAppear(_ animated: Bool) {
        guard let results = realm?.objects(RGBHueBridge.self) else {
            print("Error no bridges")
            return
        }
        authorizedBridges = Array(results)
        bridgeFinder.delegate = self
        bridgeFinder.start()
        tableView.reloadData()
    }
}

// MARK: - Table view data source
extension BridgesTableViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Authorized Bridges"
        } else if section == 1 && bridges.count > 0 {
            return "Found Bridges"
        }
        return ""
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return authorizedBridges.count
        }
        return bridges.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //swiftlint:disable:next force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: "BridgeCellIdentifier") as! BridgesTableViewCell

        switch indexPath.section {
        case 0:
            if let selectedBridge = UserDefaults.standard.object(forKey: "DefaultBridge"),
                self.authorizedBridges[indexPath.row].ipAddress == selectedBridge as? String {
                self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            }
            cell.bridge = self.authorizedBridges[indexPath.row]
        case 1:
            cell.bridge = self.bridges[indexPath.row]
        default:
            break
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            UserDefaults.standard.set(authorizedBridges[indexPath.row].ipAddress, forKey: "DefaultBridge")
        case 1:
            // Couldnt find the bridge so lets display the alert
            let bridge = bridges[indexPath.row]
            SwiftMessages.show(config: warningAlertConfig, view: linkBridgeMessageAlert)
            bridgeAuthenticator = BridgeAuthenticator(bridge: HueBridge(ip: bridge.ipAddress,
                                                                        deviceType: bridge.deviceType,
                                                                        friendlyName: bridge.friendlyName,
                                                                        modelDescription: bridge.modelDescription,
                                                                        modelName: bridge.modelName,
                                                                        serialNumber: bridge.serialNumber,
                                                                        UDN: bridge.UDN,
                                                                        icons: bridge.icons),
                                                      uniqueIdentifier: "swiftyhue#\(UIDevice.current.name)")
            selectedBridge = bridge
            bridgeAuthenticator?.delegate = self
            bridgeAuthenticator?.start()
        default:
            break
        }
    }
}

extension BridgesTableViewController: BridgeFinderDelegate {
    func bridgeFinder(_ finder: BridgeFinder, didFinishWithResult bridges: [HueBridge]) {
        for bridge in bridges {
            let contains = authorizedBridges.filter({ $0.ipAddress == bridge.ip })
            if contains.isEmpty {
                self.bridges.append(RGBHueBridge(hueBridge: bridge))
            }
        }

        if self.bridges.isEmpty {
            let emptyMessage = MessageView.viewFromNib(layout: .cardView)
            emptyMessage.configureTheme(backgroundColor: view.tintColor, foregroundColor: .white)
            emptyMessage.configureContent(title: "", body: "No new bridges found")
            emptyMessage.layoutMarginAdditions = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
            emptyMessage.button?.isHidden = true
            (emptyMessage.backgroundView as? CornerRoundingView)?.cornerRadius = 10
            SwiftMessages.show(view: emptyMessage)
        }
        tableView.reloadSections(IndexSet(arrayLiteral: 1), with: .automatic)
    }
}

extension BridgesTableViewController: BridgeAuthenticatorDelegate {
    func bridgeAuthenticator(_ authenticator: BridgeAuthenticator, didFinishAuthentication username: String) {

        // Authenticated so hide the warning
        SwiftMessages.hideAll()

        guard let selectedBridge = selectedBridge else {
            return
        }

        selectedBridge.username = username

        if let realm = realm {
            RGBDatabaseManager.write(to: realm, closure: {
                realm.add(selectedBridge)
            })
        }

        authorizedBridges.append(selectedBridge)
        bridges = bridges.filter { $0.ipAddress != selectedBridge.ipAddress }
        tableView.reloadData()
    }

    func bridgeAuthenticator(_ authenticator: BridgeAuthenticator, didFailWithError error: NSError) {
        SwiftMessages.hideAll()
        linkFailMessageAlert.configureContent(title: "", body: "Bridge link failed with error: \(error)")
        SwiftMessages.show(config: errorAlertConfig, view: linkFailMessageAlert)
    }

    func bridgeAuthenticatorRequiresLinkButtonPress(_ authenticator: BridgeAuthenticator, secondsLeft: TimeInterval) {
        print(secondsLeft)
    }

    func bridgeAuthenticatorDidTimeout(_ authenticator: BridgeAuthenticator) {
        SwiftMessages.hideAll()
        linkFailMessageAlert.configureContent(title: "",
                                              body: "Bridge link timed out.\nPlease press bridge " +
                                                    "button within 30 seconds of selecting a bridge")
        SwiftMessages.show(config: errorAlertConfig, view: linkFailMessageAlert)
    }
}
