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

        tableView.estimatedRowHeight = 600
        tableView.rowHeight = UITableView.automaticDimension

        let bridgeAccessConfig = BridgeAccessConfig(bridgeId: "BridgeId",
                                                    ipAddress: rgbBridge.ipAddress,
                                                    username: rgbBridge.username)

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

    @objc func switchChanged(_ sender: UISwitch!) {
        var lightState = LightState()

        if sender.isOn {
            lightState.on = true
        } else {
            lightState.on = false
        }

        swiftyHue.bridgeSendAPI.setLightStateForGroupWithId(groupIdentifiers[sender.tag],
                                                            withLightState: lightState, completionHandler: { _ in
            self.fetchLightsAndGroups()
        })
    }
}

extension LightGroupsTableViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groups.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // swiftlint:disable:next force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: "GroupsCellIdentifier") as! LightsGroupCustomCell

        guard let group = groups[groupIdentifiers[indexPath.row]] else {
            print("LightsGroupTableViewController: Error",
                String(describing: groups[groupIdentifiers[indexPath.row]]))
            return cell
        }

        cell.label.text = group.name

        var numberOfLightsOnIterator: Int = 0
        cell.switch.setOn(false, animated: true)
        for lightIdentifer in group.lightIdentifiers! {
            if let light = lights[lightIdentifer] {
                if light.state.on! {
                    numberOfLightsOnIterator += 1
                    cell.switch.setOn(true, animated: true)
                }
            }
        }

        // Displays how many lights currently on in group
        if numberOfLightsOnIterator == group.lightIdentifiers?.count {
            cell.numberOfLightsLabel.text = "All lights are on"
        }
        else if numberOfLightsOnIterator == 0 {
            cell.numberOfLightsLabel.text = "All lights are off"
        } else {
            let middleString = numberOfLightsOnIterator == 1 ? " light" : " lights"
            let endString = numberOfLightsOnIterator == 1 ? " is on" : " are on"
            cell.numberOfLightsLabel.text = String(format: "%@%@%@",
                                                   "\(numberOfLightsOnIterator)", middleString, endString)
        }

        cell.switch.tag = indexPath.row
        cell.switch.addTarget(self, action: #selector(self.switchChanged(_:)), for: .valueChanged)
        return cell
    }
}
