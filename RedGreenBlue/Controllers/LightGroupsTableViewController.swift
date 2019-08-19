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

        swiftyHue.setLocalHeartbeatInterval(10, forResourceType: .groups)
        swiftyHue.setLocalHeartbeatInterval(10, forResourceType: .lights)

        swiftyHue.startHeartbeat()
        NotificationCenter.default.addObserver(self, selector: #selector(onDidGroupUpdate(_:)),
                                               name: NSNotification.Name(rawValue: ResourceCacheUpdateNotification.groupsUpdated.rawValue),
                                               object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onDidLightUpdate(_:)),
                                               name: NSNotification.Name(rawValue: ResourceCacheUpdateNotification.lightsUpdated.rawValue),
                                               object: nil)

        if let cache = swiftyHue.resourceCache {
            setGroupLights(with: cache.groups)
            self.allLights = cache.lights
            print("TableView Reloading")
            tableView.reloadData()
        } else {
            APIFetchRequest.fetchLightGroups(swiftyHue: self.swiftyHue, completion: { (identifiers, groups) in
                self.lightGroups = groups
                self.groupIdentifiers = identifiers
                APIFetchRequest.fetchAllLights(swiftyHue: self.swiftyHue, completion: { (lights) in
                    self.allLights = lights
                    self.tableView.reloadData()
                })
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
        print("setGroupLights: old - \(Date.init()) \(self.lightGroups)")
        self.lightGroups = groups
        groupIdentifiers = []
        for group in lightGroups {
            groupIdentifiers.append(group.key)
        }
        groupIdentifiers.sort()
        print("setGroupLights: new - \(Date.init()) \(self.lightGroups)")
    }

    func updateCells(from sender: [String]) {
        for groupIdentifier in sender {
            //if sender == groupIdentifier { continue }
            guard let cell = tableView.cellForRow(at: IndexPath(row: groupIdentifiers.index(of: groupIdentifier)!,
                                                                section: 0)) as? LightsGroupCustomCell else {
                print("Error getting cell for row at: \(String(describing: groupIdentifiers.index(of: groupIdentifier)))")
                return
            }

            guard let group = lightGroups[groupIdentifier] else {
                return
            }

            var flag: Bool = false
            var numberOfLightsOn: Int = 0
            for identifier in group.lightIdentifiers! {
                guard let state = allLights[identifier]?.state else {
                    return
                }
                if state.on! == true {
                    numberOfLightsOn += 1
                    flag = true
                }
            }
            cell.switch.setOn(flag, animated: true)
            cell.lightBrightnessSlider.setValue(Float(group.action.brightness!) / 2.54, animated: true)
            cell.numberOfLightsLabel.text = parseNumberOfLightsOn(for: lightGroups[groupIdentifier]!, numberOfLightsOn)
        }
    }

    func parseNumberOfLightsOn(for group: Group, _ number: Int) -> String {
        // Displays how many lights currently on in group
        if number == group.lightIdentifiers?.count {
            return "All lights are on"
        } else if number == 0 {
            return "All lights are off"
        } else {
            let middleString = number == 1 ? " light" : " lights"
            let endString = number == 1 ? " is on" : " are on"
            return String(format: "%@%@%@", "\(number)", middleString, endString)
        }
    }

    // TODO: MODULARIZE
    @objc func switchChanged(_ sender: UISwitch!) {
        print("setGroupLights: switched \(Date.init())")
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
                //self.updateCells(from: self.groupIdentifiers[sender.tag])
                APIFetchRequest.fetchAllLights(swiftyHue: self.swiftyHue, completion: { (lights) in
                    self.allLights = lights
                    self.updateCells(from: self.groupIdentifiers)
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
    @objc func sliderChanged(_ sender: UISlider!, _ event: UIEvent) {
        if let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
            case .began:
                swiftyHue.stopHeartbeat()
            case .moved:
                guard previousTimer == nil else { return }
                previousTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false, block: { _ in
                    var lightState = LightState()
                    lightState.brightness = Int(sender.value * 2.54)
                    self.swiftyHue.bridgeSendAPI.setLightStateForGroupWithId(self.groupIdentifiers[sender.tag],
                                                                             withLightState: lightState,
                                                                             completionHandler: { _ in
                                                                             self.previousTimer = nil
                    })
                })
            case .ended:
                swiftyHue.startHeartbeat()
                APIFetchRequest.fetchLightGroups(swiftyHue: self.swiftyHue, completion: { (identifiers, groups) in
                    self.groupIdentifiers = identifiers
                    self.lightGroups = groups
                    self.updateCells(from: self.groupIdentifiers)
                })
            default:
                break
            }
        }
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

        cell.switch.tag = indexPath.row
        cell.switch.addTarget(self, action: #selector(self.switchChanged(_:)), for: .valueChanged)

        cell.lightBrightnessSlider.tag = indexPath.row
        cell.lightBrightnessSlider.setValue(Float(group.action.brightness!) / 2.54, animated: true)
        cell.lightBrightnessSlider.addTarget(self, action: #selector(sliderChanged(_:_:)), for: .valueChanged)
        updateCells(from: [groupIdentifiers[indexPath.row]])

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
