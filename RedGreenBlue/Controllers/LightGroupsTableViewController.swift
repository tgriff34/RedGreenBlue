//
//  LightGroupsTableViewController.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 8/16/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import UIKit
import SwiftyHue
import Gloss

class LightGroupsTableViewController: UITableViewController {

    var rgbBridge: RGBHueBridge?
    var groupIdentifiers: [String] = []

    var lightGroups: [String: Group] = [:] {
        didSet {
            print("lightGroups: Value Set")
            tableView.reloadData()
        }
    }
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

        swiftyHue.setLocalHeartbeatInterval(3, forResourceType: .config)
        swiftyHue.setLocalHeartbeatInterval(3, forResourceType: .groups)
        swiftyHue.setLocalHeartbeatInterval(3, forResourceType: .lights)
/*
        swiftyHue.setLocalHeartbeatInterval(10, forResourceType: .rules)
        swiftyHue.setLocalHeartbeatInterval(10, forResourceType: .scenes)
        swiftyHue.setLocalHeartbeatInterval(10, forResourceType: .schedules)
        swiftyHue.setLocalHeartbeatInterval(10, forResourceType: .sensors)
*/
        swiftyHue.startHeartbeat()
        NotificationCenter.default.addObserver(self, selector: #selector(onDidGroupUpdate(_:)),
                                               name: NSNotification.Name(rawValue: ResourceCacheUpdateNotification.groupsUpdated.rawValue),
                                               object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onDidLightUpdate(_:)),
                                               name: NSNotification.Name(rawValue: ResourceCacheUpdateNotification.lightsUpdated.rawValue),
                                               object: nil)

        //fetchGroups()
    }
    
    @objc func onDidGroupUpdate(_ notification: Notification) {
        if let cache = swiftyHue.resourceCache {
            self.lightGroups = cache.groups
            
            groupIdentifiers = []
            for group in lightGroups {
                groupIdentifiers.append(group.key)
            }
            groupIdentifiers.sort()
            self.tableView.reloadData()
        }
    }
    
    @objc func onDidLightUpdate(_ notification: Notification) {
        if let cache = swiftyHue.resourceCache {
            self.allLights = cache.lights
        }
    }

    func fetchGroups() {
        APIFetchRequest.fetchLightGroups(swiftyHue: self.swiftyHue, completion: { (groupIdentifiers, groups) in
            self.groupIdentifiers = groupIdentifiers
            self.lightGroups = groups
            self.tableView.reloadData()
        })
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
            print("Error sending setLightStateForGroupWithId: \(String(describing: error?.description))")
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

        if group.action.on! {
            cell.switch.setOn(true, animated: true)
        } else {
            cell.switch.setOn(false, animated: true)
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
