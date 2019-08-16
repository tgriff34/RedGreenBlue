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

class BridgesTableViewController: UITableViewController {
    var bridgeFinder = BridgeFinder()
    var bridges: [HueBridge]?
    var selectedBridge: RGBHueBridge?
    
    var bridgeAuthenticator: BridgeAuthenticator?
    
    let realm = try! Realm()
    
    //var bridgeAccessConfig: BridgeAccessConfig?
    
    //let username: String = "4g2CnLNQaVms-ZioUscRIeTaqjf6-9RocnDhYHcM"

    override func viewDidLoad() {
        super.viewDidLoad()

        bridgeFinder.delegate = self
        bridgeFinder.start()
        
        //let defaultPath = Realm.Configuration.defaultConfiguration.fileURL?.path
        //print(defaultPath)
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
            return false
        }
        
        selectedBridge = realmBridge
        
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch(segue.identifier) {
        case "ConnectedToBridgeSegue":
            guard let lightGroupsTableViewController = segue.destination as? LightGroupsTableViewController else {
                return
            }
            
            lightGroupsTableViewController.rgbBridge = selectedBridge
        default:
            print("Error with segue: \(String(describing: segue.identifier))")
        }
    }
    
    override func performSegue(withIdentifier identifier: String, sender: Any?) {
        if shouldPerformSegue(withIdentifier: identifier, sender: sender) {
            super.performSegue(withIdentifier: identifier, sender: sender)
        } else {
            guard let index = tableView.indexPathForSelectedRow?.row else {
                return
            }
            bridgeAuthenticator = BridgeAuthenticator(bridge: bridges![index], uniqueIdentifier: "swiftyhue#\(UIDevice.current.name)")
            selectedBridge = RGBHueBridge(hueBridge: bridges![index])
            bridgeAuthenticator?.delegate = self
            bridgeAuthenticator?.start()
        }
    }
}

extension BridgesTableViewController: BridgeFinderDelegate {

    func bridgeFinder(_ finder: BridgeFinder, didFinishWithResult bridges: [HueBridge]) {

        self.bridges = bridges
        //print("Dana: \(bridges)")
        
        tableView.reloadData()
        
        /*
        print(bridges[0].friendlyName)
        
        let swiftyHue = SwiftyHue()
        swiftyHue.setBridgeAccessConfig(bridgeAccessConfig)
        
        var lightState = LightState()
        lightState.on = false
        
        swiftyHue.bridgeSendAPI.setLightStateForGroupWithId("8", withLightState: lightState, completionHandler: { _ in })
        swiftyHue.bridgeSendAPI.updateLightStateForId("7", withLightState: lightState, completionHandler: {
            (errors) in
            
            print(errors)
        })
        */
    }
}

extension BridgesTableViewController: BridgeAuthenticatorDelegate {
    func bridgeAuthenticator(_ authenticator: BridgeAuthenticator, didFinishAuthentication username: String) {
        //bridgeAccessConfig = BridgeAccessConfig(bridgeId: "BrideId", ipAddress: self.bridges.ip, username: username)
        
        guard let selectedBridge = selectedBridge else {
            return
        }
        
        selectedBridge.username = username
        
        try! realm.write {
            realm.add(selectedBridge)
        }
    
        performSegue(withIdentifier: "ConnectedToBridgeSegue", sender: self)
    }
    
    func bridgeAuthenticator(_ authenticator: BridgeAuthenticator, didFailWithError error: NSError) {
        
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
        
    }
}
