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
    var bridges: [HueBridge]?
    var selectedBridge: RGBHueBridge?
    // swift
    // swiftlint:disable:next force_try
    let linkBridgeMessageAlert: MessageView = try! SwiftMessages.viewFromNib(named: "CustomMessageView")
//    let linkBridgeMessageAlert = MessageView.viewFromNib(layout: .customMessageView)
    let linkFailMessageAlert = MessageView.viewFromNib(layout: .cardView)
    var warningAlertConfig = SwiftMessages.Config()
    var errorAlertConfig = SwiftMessages.Config()

    var bridgeAuthenticator: BridgeAuthenticator?

    // swiftlint:disable:next force_try
    let realm = try! Realm()

    //var bridgeAccessConfig: BridgeAccessConfig?

    //let username: String = "4g2CnLNQaVms-ZioUscRIeTaqjf6-9RocnDhYHcM"

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

        bridgeFinder.delegate = self
        bridgeFinder.start()
    }

    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        guard let bridges = bridges else {
            return 0
        }
        return bridges.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BridgeCellIdentifier", for: indexPath)

        let realmBridge = realm.object(ofType: RGBHueBridge.self, forPrimaryKey: self.bridges?[indexPath.row].ip)
        cell.textLabel?.text = self.bridges?[indexPath.row].friendlyName

        if realmBridge != nil {
            cell.detailTextLabel?.text = "Connected"
        } else {
            cell.detailTextLabel?.text = "Not connected"
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        guard let index = tableView.indexPathForSelectedRow?.row else {
            return false
        }

        guard let realmBridge = realm.object(ofType: RGBHueBridge.self, forPrimaryKey: bridges?[index].ip) else {
            // Couldnt find the bridge so lets display the alert
            SwiftMessages.show(config: warningAlertConfig, view: linkBridgeMessageAlert)
            bridgeAuthenticator = BridgeAuthenticator(bridge: bridges![index],
                                                      uniqueIdentifier: "swiftyhue#\(UIDevice.current.name)")
            selectedBridge = RGBHueBridge(hueBridge: bridges![index])
            bridgeAuthenticator?.delegate = self
            bridgeAuthenticator?.start()
            return false
        }

        selectedBridge = realmBridge

        return true
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "ConnectedToBridgeSegue":
            guard let lightGroupsTableViewController = segue.destination as? LightGroupsTableViewController else {
                return
            }

            lightGroupsTableViewController.rgbBridge = selectedBridge
        default:
            print("Error with segue: \(String(describing: segue.identifier))")
        }
    }
}

extension BridgesTableViewController: BridgeFinderDelegate {

    func bridgeFinder(_ finder: BridgeFinder, didFinishWithResult bridges: [HueBridge]) {

        self.bridges = bridges

        tableView.reloadData()
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
        // swiftlint:disable:next force_try
        try! realm.write {
            realm.add(selectedBridge)
        }

        performSegue(withIdentifier: "ConnectedToBridgeSegue", sender: self)
    }

    func bridgeAuthenticator(_ authenticator: BridgeAuthenticator, didFailWithError error: NSError) {
        SwiftMessages.hideAll()
        linkFailMessageAlert.configureContent(title: "", body: "Bridge link failed with error: \(error)")
        SwiftMessages.show(config: errorAlertConfig, view: linkFailMessageAlert)
    }

    func bridgeAuthenticatorRequiresLinkButtonPress(_ authenticator: BridgeAuthenticator, secondsLeft: TimeInterval) {
        print(secondsLeft)
        /*
        let alert = UIAlertController(title: "Link", message: "Press the Hue link.", preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "Done", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
        */
    }

    func bridgeAuthenticatorDidTimeout(_ authenticator: BridgeAuthenticator) {
        SwiftMessages.hideAll()
        linkFailMessageAlert.configureContent(title: "",
                                              body: "Bridge link timed out.\nPlease press bridge " +
                                                    "button within 30 seconds of selecting a bridge")
        SwiftMessages.show(config: errorAlertConfig, view: linkFailMessageAlert)
    }
}
