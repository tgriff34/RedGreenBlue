//
//  InitialTableViewController.swift
//  RedGreenBlue
//
//  Created by Dana Griffin on 8/15/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import UIKit
import SwiftyHue
import RealmSwift

class InitialTableViewController: UITableViewController {
    var bridgeFinder = BridgeFinder()
    var bridges: [HueBridge]?
    var selectedBridge: RGBHueBridge?
    
    var bridgeAuthenticator: BridgeAuthenticator?
    
    let realm = try! Realm()
    
    //var bridgeAccessConfig: BridgeAccessConfig?
    
    let username: String = "4g2CnLNQaVms-ZioUscRIeTaqjf6-9RocnDhYHcM"

    override func viewDidLoad() {
        super.viewDidLoad()

        bridgeFinder.delegate = self
        bridgeFinder.start()
        
        //let defaultPath = Realm.Configuration.defaultConfiguration.fileURL?.path
        //print(defaultPath)
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source
    /*
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }
    */
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        guard let bridges = bridges else {
            return 0
        }
        return bridges.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BridgeCellIdentifier", for: indexPath)

        cell.textLabel?.text = self.bridges?[indexPath.row].friendlyName
        cell.detailTextLabel?.text = self.bridges?[indexPath.row].ip
        
        // Configure the cell...

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        selectedBridge = RGBHueBridge(bridges![indexPath.row])
        
        // Testing code
        selectedBridge!.username = username

        
        try! realm.write {
            realm.add(selectedBridge!)
        }
        
        
        // Will be live code with conditional
        
        /*
        bridgeAuthenticator = BridgeAuthenticator(bridge: bridges![indexPath.row], uniqueIdentifier: "swiftyhue#\(UIDevice.current.name)")
        
        bridgeAuthenticator?.delegate = self
        bridgeAuthenticator?.start()
         */
    }
 

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension InitialTableViewController: BridgeFinderDelegate {

    func bridgeFinder(_ finder: BridgeFinder, didFinishWithResult bridges: [HueBridge]) {

        self.bridges = bridges
        print("Dana: \(bridges)")
        
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

extension InitialTableViewController: BridgeAuthenticatorDelegate {
    func bridgeAuthenticator(_ authenticator: BridgeAuthenticator, didFinishAuthentication username: String) {
        //bridgeAccessConfig = BridgeAccessConfig(bridgeId: "BrideId", ipAddress: self.bridges.ip, username: username)
        
        guard let selectedBridge = selectedBridge else {
            return
        }
        
        selectedBridge.username = username
        
        try! realm.write {
            realm.add(selectedBridge)
        }
        
        print(selectedBridge)
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
