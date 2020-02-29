//
//  BridgesTableViewController.swift
//  RedGreenBlue
//
//  Created by Dana Griffin on 8/15/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import UIKit
import CoreData
import SwiftyHue
import SwiftMessages
import TORoundedButton
import NVActivityIndicatorView

class BridgesTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var bridgeFinder: BridgeFinder?
    var bridges = [HueBridge]()
    var selectedBridge: HueBridge?
    var authorizedBridges = [RGBHueBridge]()
    var bridgeAuthenticator: BridgeAuthenticator?

    var selectedBridgeIndex: IndexPath?

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var startBridgeFinderButton: RoundedButton!
    var activityIndicatorView: NVActivityIndicatorView?

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self

        startBridgeFinderButton.addTarget(self, action: #selector(startBridgeFinder), for: .touchUpInside)
        activityIndicatorView = NVActivityIndicatorView(frame: CGRect(x: self.view.frame.width / 2 - 50,
                                                                      y: self.view.frame.height / 2 - 50,
                                                                      width: 100, height: 100),
                                                        type: .ballPulse, color: .white, padding: 0)
        view.addSubview(activityIndicatorView!)

        navigationItem.rightBarButtonItem = editButtonItem
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: RGBDatabaseManager.KEY_RGB_HUE_BRIDGE)
        if let authorizedBridges = RGBDatabaseManager.fetch(fetchRequest: fetchRequest) as? [RGBHueBridge] {
            self.authorizedBridges = authorizedBridges
        }
        tableView.reloadData()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        SwiftMessages.hideAll()
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: animated)
        if editing {
            startBridgeFinderButton.isEnabled = false
        } else {
            startBridgeFinderButton.isEnabled = true
            tableView.selectRow(at: selectedBridgeIndex, animated: true, scrollPosition: .none)
        }
    }

    @objc func startBridgeFinder() {
        bridgeFinder = BridgeFinder()
        bridgeFinder?.delegate = self
        bridgeFinder?.start()
        startBridgeFinderButton.isEnabled = false
        activityIndicatorView?.startAnimating()
    }

    private func refreshTabViewsOnBridgeChange(_ swiftyHue: SwiftyHue) {
        let viewControllers = tabBarController?.viewControllers
        for (index, viewController) in viewControllers!.enumerated() {
            if let viewController = viewController as? UINavigationController {
                switch index {
                case 0:
                    let groupsViewController = viewController.viewControllers.first! as? LightGroupsTableViewController
                    groupsViewController?.swiftyHue = swiftyHue
                    groupsViewController?.setUpInitialView()
                    viewController.popToRootViewController(animated: true)
                case 1:
                    let scenesViewController = viewController.viewControllers.first! as? ScenesTableViewController
                    scenesViewController?.swiftyHue = swiftyHue
                    scenesViewController?.fetchData()
                    scenesViewController?.selectedGroupIndex = 0
                case 2:
                    let dynamicViewController = viewController.viewControllers.first! as? DynamicScenesViewController
                    dynamicViewController?.swiftyHue = swiftyHue
                    dynamicViewController?.fetchData()
                    dynamicViewController?.selectedGroupIndex = 0
                default:
                    break
                }
            }
        }
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
        switch indexPath.section {
        case 0:
            //swiftlint:disable:next force_cast
            let cell = tableView.dequeueReusableCell(withIdentifier: "BridgeCellIdentifier") as! BridgesTableViewCell
            if let selectedBridge = UserDefaults.standard.object(forKey: "DefaultBridge") as? String,
                self.authorizedBridges[indexPath.row].value(forKeyPath: "ipAddress") as? String == selectedBridge {
                self.selectedBridgeIndex = indexPath
                self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            }
            cell.bridge = self.authorizedBridges[indexPath.row]
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "FoundBridgeCellIdentifier")
                as! FoundBridgesTableViewCell //swiftlint:disable:this force_cast
            cell.bridge = self.bridges[indexPath.row]
            return cell
        default:
            return tableView.dequeueReusableCell(withIdentifier: "BridgeCellIdentifier")!
        }
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            let selectedBridge = authorizedBridges[indexPath.row]

            guard let ipAddress = selectedBridge.value(forKeyPath: "ipAddress") as? String else {
                return
            }

            let newSwiftyHue = RGBRequest.shared.setSwiftyHue(ipAddress: ipAddress)
            refreshTabViewsOnBridgeChange(newSwiftyHue)

            tableView.deselectRow(at: selectedBridgeIndex!, animated: true)
            selectedBridgeIndex = indexPath
        case 1:
            // Couldnt find the bridge so lets display the alert
            let bridge = bridges[indexPath.row]

            let warningAlertView = RGBSwiftMessages
                .createAlertInView(type: .info, fromNib: .infiniteSpinner,
                                   forever: true, content: ("", "Please press the button on your Hue bridge"))
            let warningAlertConfig = RGBSwiftMessages
                .createMessageConfig(duration: .forever, dim: true, interactiveHide: false)
            SwiftMessages.show(config: warningAlertConfig, view: warningAlertView)

            bridgeAuthenticator = BridgeAuthenticator(
                bridge: HueBridge(ip: bridge.ip, deviceType: bridge.deviceType,
                                  friendlyName: bridge.friendlyName, modelDescription: bridge.modelDescription,
                                  modelName: bridge.modelName, serialNumber: bridge.serialNumber,
                                  UDN: bridge.UDN, icons: bridge.icons),
                uniqueIdentifier: "swiftyhue#\(UIDevice.current.name)")
            selectedBridge = bridge
            bridgeAuthenticator?.delegate = self
            bridgeAuthenticator?.start()
            self.tableView.deselectRow(at: indexPath, animated: false)
            self.tableView.allowsSelection = false
        default:
            break
        }
    }
    func tableView(_ tableView: UITableView, willDeselectRowAt indexPath: IndexPath) -> IndexPath? {
        if indexPath.section == 0, indexPath == selectedBridgeIndex {
            return nil
        }
        return indexPath
    }
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 0
    }
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath)
        -> UITableViewCell.EditingStyle {
        if tableView.isEditing {
            return .delete
        }
        return .none
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if indexPath == selectedBridgeIndex {
                let cantDeleteRowMessage = RGBSwiftMessages
                    .createAlertInView(type: .warning, fromNib: .cardView,
                                       content: ("", "You may not delete a bridge that is selected."))
                let cantDeleteRowConfig = RGBSwiftMessages.createMessageConfig()
                SwiftMessages.show(config: cantDeleteRowConfig, view: cantDeleteRowMessage)
            } else {
                let bridge = authorizedBridges[indexPath.row]
                RGBDatabaseManager.delete(bridge)
                authorizedBridges.remove(at: indexPath.row)
                self.tableView.deleteRows(at: [indexPath], with: .automatic)
            }
        }
    }
}

extension BridgesTableViewController: BridgeFinderDelegate {
    func bridgeFinder(_ finder: BridgeFinder, didFinishWithResult bridges: [HueBridge]) {
        var foundNewUndiscoveredBridges: Bool = false
        for bridge in bridges {
            let alreadyAuthorizedBridge = self.authorizedBridges.filter({
                //swiftlint:disable:next force_cast
                $0.value(forKeyPath: "ipAddress") as! String == bridge.ip
            })
            let alreadyFoundBridge = self.bridges.filter({ $0.ip == bridge.ip })
            if alreadyAuthorizedBridge.isEmpty && alreadyFoundBridge.isEmpty {
                self.bridges.append(bridge)
                foundNewUndiscoveredBridges = true
            }
        }

        if !foundNewUndiscoveredBridges {
            let noNewBridgesMessage = RGBSwiftMessages
                .createAlertInView(type: .info, fromNib: .cardView,
                                   content: ("No new bridges found", ""),
                                   layoutMarginAdditions: UIEdgeInsets(top: 5, left: 20, bottom: 10, right: 20))
            let noNewBridgesConfig = RGBSwiftMessages.createMessageConfig()
            SwiftMessages.show(config: noNewBridgesConfig, view: noNewBridgesMessage)
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

        RGBDatabaseManager.addBridge(selectedBridge, username, completion: { (newBridge, error) in
            if error != nil {
                return
            }
            self.authorizedBridges.append(newBridge)
            self.bridges = self.bridges.filter { $0.ip != selectedBridge.ip }
        })
        self.tableView.allowsSelection = true
        tableView.reloadData()
    }
    func bridgeAuthenticator(_ authenticator: BridgeAuthenticator, didFailWithError error: NSError) {
        SwiftMessages.hideAll()
        let linkTimeoutError = RGBSwiftMessages
            .createAlertInView(type: .error, fromNib: .cardView, forever: true,
                               content: ("", "Bridge link failed with error: \(error)"))
        let linkTimeoutErrorConfig = RGBSwiftMessages.createMessageConfig(dimInteractive: true)
        SwiftMessages.show(config: linkTimeoutErrorConfig, view: linkTimeoutError)
        self.tableView.allowsSelection = true
    }
    func bridgeAuthenticatorRequiresLinkButtonPress(_ authenticator: BridgeAuthenticator, secondsLeft: TimeInterval) {
        // seconds left until it stops waiting for button press
    }
    func bridgeAuthenticatorDidTimeout(_ authenticator: BridgeAuthenticator) {
        SwiftMessages.hideAll()
        let linkTimeoutError = RGBSwiftMessages
            .createAlertInView(type: .error, fromNib: .cardView, forever: true,
                               content: ("", "Bridge link timed out.\nPlease press bridge " +
                                         "button within 30 seconds of selecting a bridge"))
        let linkTimeoutErrorConfig = RGBSwiftMessages.createMessageConfig(dimInteractive: true)
        SwiftMessages.show(config: linkTimeoutErrorConfig, view: linkTimeoutError)
        self.tableView.allowsSelection = true
    }
}
