//
//  LightGroupsTableViewController.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 8/16/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import UIKit
import SwiftyHue

class LightGroupsTableViewController: UITableViewController {
    
    var rgbBridge: RGBHueBridge?
    var groupIdentifiers: [String] = []
    
    var lights: [String: Light] = [:]
    var groups: [String: Group] = [:]
    let swiftyHue = SwiftyHue()

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        guard let rgbBridge = rgbBridge else {
            return
        }
        
        let bridgeAccessConfig = BridgeAccessConfig(bridgeId: "BridgeId", ipAddress: rgbBridge.ipAddress, username: rgbBridge.username)
        
        swiftyHue.setBridgeAccessConfig(bridgeAccessConfig)
        fetchLightsAndGroups()
    }
    
    func fetchLightsAndGroups() {
        APIFetchRequest.fetchLightGroups(swiftyHue: self.swiftyHue, completion: { (groupIdentifiers, groups) in
            self.groupIdentifiers = groupIdentifiers
            self.groups = groups
            
            APIFetchRequest.fetchAllLights(swiftyHue: self.swiftyHue, completion: { lights in
                self.lights = lights
                self.tableView.reloadData()
            })
        })
    }
    
    @objc func switchChanged(_ sender : UISwitch!) {
        var lightState = LightState()
        
        if sender.isOn {
            lightState.on = true
        } else {
            lightState.on = false
        }
        
        swiftyHue.bridgeSendAPI.setLightStateForGroupWithId(groupIdentifiers[sender.tag], withLightState: lightState, completionHandler: { _ in
            self.fetchLightsAndGroups()
        })
    }
}

extension LightGroupsTableViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groups.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GroupsCellIdentifier") as! LightsGroupCustomCell
        
        guard let group = groups[groupIdentifiers[indexPath.row]] else {
            print("LightsGroupTableViewController: Error \(String(describing: groups[groupIdentifiers[indexPath.row]]))")
            return cell
        }
        
        cell.label.text = group.name
        
        cell.switch.setOn(false, animated: true)
        for lightIdentifer in group.lightIdentifiers! {
            if let light = lights[lightIdentifer] {
                if light.state.on! {
                    cell.switch.setOn(true, animated: true)
                }
            }
        }
        cell.switch.tag = indexPath.row
        cell.switch.addTarget(self, action: #selector(self.switchChanged(_:)), for: .valueChanged)
 
        return cell
    }
}
