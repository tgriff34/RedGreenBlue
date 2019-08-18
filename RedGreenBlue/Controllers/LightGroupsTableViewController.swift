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

    var lightGroups: [String: Group] = [:]
    var allLights: [String: Light] = [:]
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
        fetchGroups()
    }

    func fetchGroups() {
        APIFetchRequest.fetchLightGroups(swiftyHue: self.swiftyHue, completion: { (groupIdentifiers, groups) in
            self.groupIdentifiers = groupIdentifiers
            self.lightGroups = groups
            self.tableView.reloadData()
        })
    }

    func numberOfLightsOn(in group: Group) -> Int {
        var result = 0
        APIFetchRequest.fetchAllLights(swiftyHue: swiftyHue, completion: { (lights) in
            for identifier in group.lightIdentifiers ?? [] {
                if lights[identifier]?.state.on ?? false {
                    result += 1
                }
            }
        })
        return result
    }

    // TODO: MODULARIZE
    @objc func switchChanged(_ sender: UISwitch!) {
        var lightState = LightState()

        if sender.isOn {
            lightState.on = true
        } else {
            lightState.on = false
        }

        swiftyHue.bridgeSendAPI.setLightStateForGroupWithId(groupIdentifiers[sender.tag],
                                                            withLightState: lightState, completionHandler: { _ in
            self.fetchGroups()
        })
    }

    // TODO: MODULARIZE
    private var previousTimer: Timer? = nil {
        willSet {
            previousTimer?.invalidate()
        }
    }
    @IBAction func sliderChanged(_ sender: UISlider!) {
        guard previousTimer == nil else { return }
        previousTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false, block: { _ in
            var lightState = LightState()
            lightState.brightness = Int(sender.value * 25.4)
            self.swiftyHue.bridgeSendAPI.setLightStateForGroupWithId(self.groupIdentifiers[sender.tag],
                                                                     withLightState: lightState,
                                                                     completionHandler: { _ in
                                                                     self.previousTimer = nil
            })
        })
    }
}

// MARK: - TABLEVIEW
extension LightGroupsTableViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return lightGroups.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // swiftlint:disable:next force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: "GroupsCellIdentifier") as! LightsGroupCustomCell

        guard let group = lightGroups[groupIdentifiers[indexPath.row]] else {
            print("LightsGroupTableViewController: Error",
                String(describing: lightGroups[groupIdentifiers[indexPath.row]]))
            return cell
        }

        cell.label.text = group.name

        if group.action.on ?? false {
            cell.switch.setOn(true, animated: true)
        } else {
            cell.switch.setOn(false, animated: true)
        }

        // Displays how many lights currently on in group
        let lightsOn = numberOfLightsOn(in: group)
        if lightsOn == group.lightIdentifiers?.count {
            cell.numberOfLightsLabel.text = "All lights are on"
        } else if lightsOn == 0 {
            cell.numberOfLightsLabel.text = "All lights are off"
        } else {
            let middleString = lightsOn == 1 ? " light" : " lights"
            let endString = lightsOn == 1 ? " is on" : " are on"
            cell.numberOfLightsLabel.text = String(format: "%@%@%@",
                                                   "\(lightsOn)", middleString, endString)
        }

        cell.switch.tag = indexPath.row
        cell.switch.addTarget(self, action: #selector(self.switchChanged(_:)), for: .valueChanged)

        cell.lightBrightnessSlider.tag = indexPath.row
        cell.lightBrightnessSlider.setValue(Float(group.action.brightness!) / 25.4, animated: true)
        cell.lightBrightnessSlider.addTarget(self, action: #selector(sliderChanged(_:)), for: .valueChanged)

        return cell
    }
}

// MARK: - NAVIGATION
extension LightGroupsTableViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "SelectedLightGroupSegue":
            guard let lightTableViewController = segue.destination as? LightTableViewController,
                let index = tableView.indexPathForSelectedRow?.row else {
                    print("Error could not cast \(segue.destination) as LightTableViewController")
                    print("Error could not get index selected:",
                          "\(String(describing: tableView.indexPathForSelectedRow?.row))",
                        " from tableview.indexPathForSelectedRow?.row")
                    return
            }
            lightTableViewController.swiftyHue = swiftyHue
            lightTableViewController.lightIdentifiers = lightGroups[groupIdentifiers[index]]?.lightIdentifiers
            lightTableViewController.title = lightGroups[groupIdentifiers[index]]?.name

        default:
            print("Error performing segue: \(String(describing: segue.identifier))")
        }
    }
}

//extension Array where Element ==
