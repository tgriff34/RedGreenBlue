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
    var groups = [[RGBGroup]]()
    var swiftyHue: SwiftyHue!

    override func viewDidLoad() {
        super.viewDidLoad()

        swiftyHue = RGBRequest.shared.getSwiftyHue()

        tableView.estimatedRowHeight = 80
        tableView.rowHeight = UITableView.automaticDimension
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Observer for when the lights change in another app or wall switch
        NotificationCenter.default.addObserver(
            self, selector: #selector(onDidLightUpdate(_:)),
            name: NSNotification.Name(rawValue: ResourceCacheUpdateNotification.lightsUpdated.rawValue),
            object: nil)
        setUpInitialView()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Remove the observer when navigating away
        NotificationCenter.default.removeObserver(
            self, name: NSNotification.Name(
                rawValue: ResourceCacheUpdateNotification.lightsUpdated.rawValue),
            object: nil)
    }

    // MARK: - Private Funcs
    @objc func onDidLightUpdate(_ notification: Notification) {
        if let cache = swiftyHue.resourceCache {
            for light in Array(cache.lights.values) {
                for (section, groupsByType) in groups.enumerated() {
                    for (row, group) in groupsByType.enumerated()
                        where group.lightIdentifiers.contains(light.identifier) {
                        if let lightIndex = group.lights.firstIndex(where: { $0.identifier == light.identifier }) {
                            self.groups[section][row].lights[lightIndex] = light
                        }
                    }
                }
            }
            self.fetchData(completion: {
                self.tableView.beginUpdates()
                self.tableView.endUpdates()
            })
        }
    }

    func setUpInitialView() {
        // Initial app startup
        if groups.isEmpty {
            swiftyHue = RGBRequest.shared.getSwiftyHue()
            fetchData(completion: {
                self.tableView.reloadData()
            })
        } else {
            fetchData(completion: {
                // Check to see if the user has added groups or rooms in another app
                // If so, reload the tableView
                if self.tableView.numberOfRows(inSection: 0) != self.groups[0].count ||
                    self.tableView.numberOfRows(inSection: 1) != self.groups[1].count {
                    self.tableView.reloadData()
                }
                // These updates are to adjust cell height
                self.tableView.beginUpdates()
                self.tableView.endUpdates()
            })
        }
    }

    // Fetch all groups and lights and update cells
    private func fetchData(completion: (() -> Void)?) {
        RGBRequest.shared.getGroups(with: self.swiftyHue, completion: { (groups, error) in
            // Catch any errors
            guard error == nil, let groups = groups else {
                RGBRequest.shared.errorsFromResponse(error: error, completion: {
                    // If there is an error retry getting the groups
                    // This is needed if the user is disconnected from wifi and reconnects
                    self.setUpInitialView()
                })
                return
            }
            // Set the current groups to fetched groups
            self.groups = groups
            self.updateUI()
            completion?()
        })
    }

    // updateUI() is used as a way of updating the cells without using tableView.reloadData().
    // It updates the cell group with a new group from the datasource.
    // This prevents weird UI flashes from happening from using tableView.reloadData().
    private func updateUI() {
        // This iterates through the 2D array of groups
        for (section, groupsByType) in groups.enumerated() {
            for (row, subGroup) in groupsByType.enumerated() {
                // Gets the cell for the group at that row
                let cell = tableView.cellForRow(at: IndexPath(row: row, section: section)) as? LightsGroupCustomCell
                // Updates the cell group to new group from 2D array
                cell?.group = subGroup
            }
        }
    }

    private func updateLightsBrightnessForGroup(group: RGBGroup, value: Float) {
        for light in group.lights where light.state.on! == true {
            // Set light state based on slider value.
            // Slider value is 1 - 100, but API takes 0 - 254,
            // multiplication takes care of the difference
            var lightState = LightState()
            lightState.brightness = Int(value * 2.54)
            RGBGroupsAndLightsHelper.shared.setLightState(
                for: light, using: swiftyHue, with: lightState, completion: nil)
        }
    }
}

// MARK: - TABLEVIEW
extension LightGroupsTableViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return groups.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Rooms"
        } else if section == 1 && !groups[1].isEmpty {
            return "Groups"
        } else {
            return ""
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return groups[0].count
        }
        return groups[1].count
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell,
                            forRowAt indexPath: IndexPath) {
        // Allows for smoother scrolling for card view
        cell.contentView.layer.masksToBounds = true
        let radius = cell.contentView.layer.cornerRadius
        cell.layer.shadowPath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: radius).cgPath
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // swiftlint:disable:next force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: "GroupsCellIdentifier") as! LightsGroupCustomCell
        cell.group = groups[indexPath.section][indexPath.row]
        cell.delegate = self
        return cell
    }
}

// MARK: - Groups Cell Delegate
extension LightGroupsTableViewController: LightsGroupsCellDelegate {
    // Light switch tapped delegate
    func lightGroupsTableViewCell(_ lightGroupsTableViewCell: LightsGroupCustomCell,
                                  lightSwitchTappedFor group: RGBGroup) {
        // Set the lightstate on property based on whether the switch is on or not.
        var lightState = LightState()
        lightState.on = lightGroupsTableViewCell.switch.isOn

        // Set lightstate...
        RGBGroupsAndLightsHelper.shared.setLightState(
            for: group, using: swiftyHue, with: lightState, completion: {
                // Update the tableview once data has hit the bridge
                self.fetchData(completion: {
                    // These updates allow the cell height to change to the correct size.
                    self.tableView.beginUpdates()
                    self.tableView.endUpdates()
                })
        })
    }

    // Brightness slider started moving
    func lightGroupsTableViewCell(_ lightGroupTableViewCell: LightsGroupCustomCell,
                                  lightSliderStartedFor group: RGBGroup) {
        // Make sure to stop the heartbeat when the slider has started sliding.
        // Otherwise the slider will move underneath the user finger,
        // because of the heartbeat fetch.
        swiftyHue.stopHeartbeat()
    }

    // Brightness slider is moving
    func lightGroupsTableViewCell(_ lightGroupsTableViewCell: LightsGroupCustomCell,
                                  lightSliderMovedFor group: RGBGroup) {
        // Send the value of the slider to the bridges with the timeInterval provided.
        // 0.25 is the fastest you will want to do.
        RGBGroupsAndLightsHelper.shared.sendTimeSensistiveAPIRequest(withTimeInterval: 0.25, completion: {
            self.updateLightsBrightnessForGroup(group: group, value: lightGroupsTableViewCell.slider.value)
        })
    }

    // Brightness slider stopped moving
    func lightGroupsTableViewCell(_ lightGroupTableViewCell: LightsGroupCustomCell,
                                  lightSliderEndedFor group: RGBGroup) {
        // Once user stopped sliding, update lights with current value, no need to wait 0.25 seconds.
        self.updateLightsBrightnessForGroup(group: group, value: lightGroupTableViewCell.slider.value)
        // Fetch the data and start the heart beat once the tableview has updated.
        self.fetchData(completion: { self.swiftyHue.startHeartbeat() })
    }
}

// MARK: - Add Group Delegate
extension LightGroupsTableViewController: GroupAddDelegate {
    func groupAddedSuccess(_ name: String, _ lights: [String]) {
        // Group is added, create group and reload table view
        swiftyHue.bridgeSendAPI.createGroupWithName(
            name, andType: .LightGroup, includeLightIds: lights, completionHandler: { _ in
                self.fetchData(completion: { self.tableView.reloadData() })
        })
    }
}

// MARK: - NAVIGATION
extension LightGroupsTableViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        // User wants to edit the group they just selected. Set the initial values
        // in the view controller to group that was selected
        case "SelectedLightGroupSegue":
            let lightTableViewController = segue.destination as? LightTableViewController

            // Make sure to get the index for the row that was just selected
            guard let index = tableView.indexPathForSelectedRow else {
                logger.error("could not get index selected:",
                      "\(String(describing: tableView.indexPathForSelectedRow?.row))",
                    " from tableview.indexPathForSelectedRow?.row")
                    return
            }
            lightTableViewController?.swiftyHue = swiftyHue
            lightTableViewController?.title = groups[index.section][index.row].name
            lightTableViewController?.group = groups[index.section][index.row]

        // User wants to add a group, set all attributes in following to initial values
        // and set this controller as the delegate for when the user saves that new group
        case "AddGroupSegue":
            let navigationController = segue.destination as? UINavigationController
            let lightGroupsAddEditViewController = navigationController?.viewControllers.first!
                as? LightGroupsAddEditViewController
            lightGroupsAddEditViewController?.group = nil
            lightGroupsAddEditViewController?.swiftyHue = swiftyHue
            lightGroupsAddEditViewController?.name = ""
            lightGroupsAddEditViewController?.selectedLights = []
            lightGroupsAddEditViewController?.addGroupDelegate = self
        default:
            logger.error("performing segue: \(String(describing: segue.identifier))")
        }
    }
}
