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
import TORoundedButton
import NVActivityIndicatorView

class BridgesTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var bridgeFinder: BridgeFinder?
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

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var startBridgeFinderButton: RoundedButton!
    var activityIndicatorView: NVActivityIndicatorView?

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self

        logger.info("REALM FILE PATH: \(String(describing: realm?.configuration.fileURL))")
        console.info("REALM FILE PATH: \(String(describing: realm?.configuration.fileURL))")

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

        startBridgeFinderButton.addTarget(self, action: #selector(startBridgeFinder), for: .touchUpInside)
        activityIndicatorView = NVActivityIndicatorView(frame: CGRect(x: self.view.frame.width / 2 - 50,
                                                                      y: self.view.frame.height / 2 - 50,
                                                                      width: 100, height: 100),
                                                        type: .ballPulse, color: .white, padding: 0)
        view.addSubview(activityIndicatorView!)
    }

    override func viewWillAppear(_ animated: Bool) {
        guard let results = realm?.objects(RGBHueBridge.self) else {
            logger.error("no bridges")
            return
        }
        authorizedBridges = Array(results)

        tableView.reloadData()
    }

    @objc func startBridgeFinder() {
        bridgeFinder = BridgeFinder()
        bridgeFinder?.delegate = self
        bridgeFinder?.start()
        startBridgeFinderButton.isEnabled = false
        activityIndicatorView?.startAnimating()
    }
}

// MARK: - Table view data source
extension BridgesTableViewController {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Authorized Bridges"
        } else if section == 1 && bridges.count > 0 {
            return "Found Bridges"
        }
        return ""
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return authorizedBridges.count
        }
        return bridges.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
        var foundNewUndiscoveredBridges: Bool = false
        for bridge in bridges {
            let alreadyAuthorizedBridge = self.authorizedBridges.filter({ $0.ipAddress == bridge.ip })
            let alreadyFoundBridge = self.bridges.filter({ $0.ipAddress == bridge.ip })
            if alreadyAuthorizedBridge.isEmpty && alreadyFoundBridge.isEmpty {
                self.bridges.append(RGBHueBridge(hueBridge: bridge))
                foundNewUndiscoveredBridges = true
            }
        }

        if !foundNewUndiscoveredBridges {
            // swiftlint:disable:next force_try
            let emptyMessage: MessageView = try! SwiftMessages.viewFromNib(named: "SuccessCustomMessage")
            var emptyMessageConfig = SwiftMessages.Config()
            emptyMessageConfig.presentationContext = .window(windowLevel: .normal)
            emptyMessage.configureTheme(backgroundColor: view.tintColor, foregroundColor: .white)
            emptyMessage.configureContent(title: "No new bridges found", body: "")
            emptyMessage.layoutMarginAdditions = UIEdgeInsets(top: 5, left: 20, bottom: 10, right: 20)
            emptyMessage.button?.isHidden = true
            (emptyMessage.backgroundView as? CornerRoundingView)?.cornerRadius = 10
            SwiftMessages.show(config: emptyMessageConfig, view: emptyMessage)
        } else {
            tableView.reloadSections(IndexSet(arrayLiteral: 1), with: .automatic)
        }
        startBridgeFinderButton.isEnabled = true
        activityIndicatorView?.stopAnimating()
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
        // seconds left until it stops waiting for button press
    }

    func bridgeAuthenticatorDidTimeout(_ authenticator: BridgeAuthenticator) {
        SwiftMessages.hideAll()
        linkFailMessageAlert.configureContent(title: "",
                                              body: "Bridge link timed out.\nPlease press bridge " +
                                                    "button within 30 seconds of selecting a bridge")
        SwiftMessages.show(config: errorAlertConfig, view: linkFailMessageAlert)
    }
}
