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

    private let API_KEY: String = "API_KEY" //swiftlint:disable:this identifier_name
    private let CACHE_KEY: String = "CACHE_KEY" //swiftlint:disable:this identifier_name

    var rgbBridge: RGBHueBridge?
    var groupIdentifiers: [String] = []
    var lightGroups: [String: Group] = [:]
    var allLights: [String: Light] = [:]
    let swiftyHue = SwiftyHue()

    override func viewDidLoad() {
        super.viewDidLoad()

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
                                               name: NSNotification.Name(rawValue: ResourceCacheUpdateNotification.groupsUpdated.rawValue), // swiftlint:disable:this line_length
            object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onDidLightUpdate(_:)),
                                               name: NSNotification.Name(rawValue: ResourceCacheUpdateNotification.lightsUpdated.rawValue), // swiftlint:disable:this line_length
            object: nil)

        fetchGroupsAndLights {
            self.tableView.reloadData()
            self.updateCells(ignoring: nil, from: self.CACHE_KEY, completion: nil)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        self.updateCells(ignoring: nil, from: CACHE_KEY, completion: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        swiftyHue.stopHeartbeat()
    }

    // MARK: - Private Funcs
    @objc func onDidGroupUpdate(_ notification: Notification) {
        if let cache = swiftyHue.resourceCache {
            self.lightGroups = cache.groups
            self.groupIdentifiers = RGBGroupsAndLightsHelper.retrieveGroupIds(from: self.lightGroups)
            self.updateCells(ignoring: nil, from: CACHE_KEY, completion: nil)
        }
    }

    @objc func onDidLightUpdate(_ notification: Notification) {
        if let cache = swiftyHue.resourceCache {
            self.allLights = cache.lights
            self.updateCells(ignoring: nil, from: CACHE_KEY, completion: nil)
        }
    }

    // Fetch all groups and lights and update cells
    func fetchGroupsAndLights(completion: @escaping () -> Void) {
        RGBRequest.getGroups(with: self.swiftyHue, completion: { (groups) in
            self.lightGroups = groups
            self.groupIdentifiers = RGBGroupsAndLightsHelper.retrieveGroupIds(from: self.lightGroups)
            RGBRequest.getLights(with: self.swiftyHue, completion: { (lights) in
                self.allLights = lights
                self.swiftyHue.startHeartbeat()
                completion()
            })
        })
    }

    func updateCells(ignoring cell: String?, from KEY: String, completion: (() -> Void)?) {
        switch KEY {
        case API_KEY:
            fetchGroupsAndLights(completion: {
                print("Updating cells from api")
                self.updateCellsToScreen(ignoring: cell)
            })
        case CACHE_KEY:
            print("Updating cells from cache")
            updateCellsToScreen(ignoring: cell)
        default:
            print("Error updating cells from KEY: ", KEY)
        }
    }

    func updateCellsToScreen(ignoring cell: String?) {
        for groupIdentifier in self.groupIdentifiers {
            if cell == groupIdentifier { continue }
            guard let cell =
                self.tableView.cellForRow(at: IndexPath(row: self.groupIdentifiers.index(of: groupIdentifier)!,
                                                        section: 0)) as? LightsGroupCustomCell
                else {
                    print("Error getting cell for row at:",
                          "\(String(describing: self.groupIdentifiers.index(of: groupIdentifier)))")
                    return
            }

            guard let group = self.lightGroups[groupIdentifier] else {
                return
            }

            var flag: Bool = false
            var numberOfLightsOn: Int = 0
            var averageBrightnessOfLightsOn: Int = 0
            for identifier in group.lightIdentifiers! {
                guard let state = self.allLights[identifier]?.state else {
                    return
                }
                if state.on! == true {
                    averageBrightnessOfLightsOn += state.brightness!
                    numberOfLightsOn += 1
                    flag = true
                }
            }
            cell.switch.setOn(flag, animated: true)
            cell.numberOfLightsLabel.text = self.parseNumberOfLightsOn(for: self.lightGroups[groupIdentifier]!,
                                                                       numberOfLightsOn)

            if numberOfLightsOn > 0 {
                UIView.animate(withDuration: 1, animations: {
                    cell.lightBrightnessSlider.setValue(Float(averageBrightnessOfLightsOn / numberOfLightsOn) / 2.54,
                                                        animated: true)
                })
            } else {
                UIView.animate(withDuration: 1, animations: {
                    cell.lightBrightnessSlider.setValue(1, animated: true)
                })
            }
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

    @objc func switchChanged(_ sender: UISwitch!) {
        print("setGroupLights: switched \(Date.init())")
        var lightState = LightState()
        if sender.isOn {
            lightState.on = true
        } else {
            lightState.on = false
        }
        swiftyHue.bridgeSendAPI.setLightStateForGroupWithId(groupIdentifiers[sender.tag],
                                                            withLightState: lightState,
                                                            completionHandler: { (error) in
                                                            guard error == nil else {
                                                                print("Error sending setLightStateForGroupWithId:",
                                                                      "\(String(describing: error?.description))")
                                                                return
                                                            }
                                                            self.updateCells(ignoring: nil,
                                                                             from: self.API_KEY,
                                                                             completion: nil)
        })
    }

    private var previousTimer: Timer? = nil {
        willSet {
            previousTimer?.invalidate()
        }
    }
    @objc func sliderChanged(_ sender: UISlider!, _ event: UIEvent) {
        if let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
            case .began:
                print("Slider: stopping hearbeat")
                swiftyHue.stopHeartbeat()
            case .moved:
                guard previousTimer == nil else { return }
                previousTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false, block: { _ in
                    self.updateLightsBrightnessForGroup(at: sender.tag, with: sender.value)
                })
            case .ended:
                print("Slider: starting heartbeat")
                self.updateLightsBrightnessForGroup(at: sender.tag, with: sender.value)
                print("Slider: \(sender.tag) \(sender.value)")
                self.updateCells(ignoring: self.groupIdentifiers[sender.tag], from: self.API_KEY, completion: nil)
            default:
                break
            }
        }
    }

    func updateLightsBrightnessForGroup(at index: Int, with value: Float) {
        guard let group = self.lightGroups[self.groupIdentifiers[index]] else {
            return
        }
        for identifier in group.lightIdentifiers! {
            guard let state = self.allLights[identifier]?.state else {
                return
            }
            if state.on! == true {
                var lightState = LightState()
                lightState.brightness = Int(value * 2.54)
                self.swiftyHue.bridgeSendAPI.updateLightStateForId(identifier,
                                                                   withLightState: lightState,
                                                                   transitionTime: nil,
                                                                   completionHandler: { _ in self.previousTimer = nil })
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
        cell.lightBrightnessSlider.addTarget(self, action: #selector(sliderChanged(_:_:)), for: .valueChanged)

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
