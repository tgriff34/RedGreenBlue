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

        swiftyHue.setLocalHeartbeatInterval(3, forResourceType: .groups)
        swiftyHue.setLocalHeartbeatInterval(3, forResourceType: .lights)

        swiftyHue.startHeartbeat()
        NotificationCenter.default.addObserver(self, selector: #selector(onDidGroupUpdate(_:)),
                                               name: NSNotification.Name(rawValue: ResourceCacheUpdateNotification.groupsUpdated.rawValue),
                                               object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onDidLightUpdate(_:)),
                                               name: NSNotification.Name(rawValue: ResourceCacheUpdateNotification.lightsUpdated.rawValue),
                                               object: nil)

        if let cache = swiftyHue.resourceCache {
            print("Received groups from cache: \(cache.groups)")
            setGroupLights(with: cache.groups)
            self.allLights = cache.lights
            tableView.reloadData()
        } else {
            APIFetchRequest.fetchLightGroups(swiftyHue: swiftyHue, completion: { (identifiers, groups) in
                print("Received groups from API: \(groups)")
                self.lightGroups = groups
                self.groupIdentifiers = identifiers
                self.tableView.reloadData()
            })
        }
    }

    @objc func onDidGroupUpdate(_ notification: Notification) {
        if let cache = swiftyHue.resourceCache {
            setGroupLights(with: cache.groups)
        }
    }

    @objc func onDidLightUpdate(_ notification: Notification) {
        if let cache = swiftyHue.resourceCache {
            self.allLights = cache.lights
        }
    }

    func setGroupLights(with groups: [String: Group]) {
        self.lightGroups = groups
        groupIdentifiers = []
        for group in lightGroups {
            groupIdentifiers.append(group.key)
        }
        groupIdentifiers.sort()
    }

    func updateCells(from sender: String) {
        print("UPDATE CELLS")
        for groupIdentifier in groupIdentifiers {
            if sender == groupIdentifier { continue }
            guard let cell = tableView.cellForRow(at: IndexPath(row: groupIdentifiers.index(of: groupIdentifier)!,
                                                                section: 0)) as? LightsGroupCustomCell else {
                print("Error getting ceel for row at: ")
                return
            }

            guard let groupLightIdentifiers = lightGroups[groupIdentifier]?.lightIdentifiers else {
                return
            }

            var flag: Bool = false
            for identifier in groupLightIdentifiers {
                guard let state = allLights[identifier]?.state else {
                    return
                }
                if state.on! == true {
                    flag = true
                }
            }
            print("UPDATE: \(flag)")
            cell.switch.setOn(flag, animated: true)
        }
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
                                                            withLightState: lightState, completionHandler: { (error) in
            guard error == nil else {
                print("Error sending setLightStateForGroupWithId: \(String(describing: error?.description))")
                return
            }
            APIFetchRequest.fetchLightGroups(swiftyHue: self.swiftyHue, completion: { (identifiers, groups) in
                self.lightGroups = groups
                self.groupIdentifiers = identifiers
                APIFetchRequest.fetchAllLights(swiftyHue: self.swiftyHue, completion: { (lights) in
                    self.allLights = lights
                    self.updateCells(from: self.groupIdentifiers[sender.tag])
                })
            })
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
            lightState.brightness = Int(sender.value)
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

        var flag: Bool = false
        var numberOfLightsOnIterator = 0
        for lightIdentifier in group.lightIdentifiers! {
            guard let light = allLights[lightIdentifier] else {
                return cell
            }
            if light.state.on! {
                flag = true
                numberOfLightsOnIterator += 1
            }
        }
        
        cell.switch.setOn(flag, animated: true)
        
        // Displays how many lights currently on in group
        if numberOfLightsOnIterator == group.lightIdentifiers?.count {
            cell.numberOfLightsLabel.text = "All lights are on"
        } else if numberOfLightsOnIterator == 0 {
            cell.numberOfLightsLabel.text = "All lights are off"
        } else {
            let middleString = numberOfLightsOnIterator == 1 ? " light" : " lights"
            let endString = numberOfLightsOnIterator == 1 ? " is on" : " are on"
            cell.numberOfLightsLabel.text = String(format: "%@%@%@",
                                                   "\(numberOfLightsOnIterator)", middleString, endString)
        }

        cell.switch.tag = indexPath.row
        cell.switch.addTarget(self, action: #selector(self.switchChanged(_:)), for: .valueChanged)

        cell.lightBrightnessSlider.tag = indexPath.row
        cell.lightBrightnessSlider.setValue(Float(group.action.brightness!), animated: true)
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
