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

        tableView.estimatedRowHeight = 200
        tableView.rowHeight = UITableView.automaticDimension

        NotificationCenter.default.addObserver(self, selector: #selector(onDidLightUpdate(_:)),
                                               name: NSNotification.Name(rawValue:
                                                ResourceCacheUpdateNotification.lightsUpdated.rawValue),
                                               object: nil)

        console.debug(RGBDatabaseManager.realm()?.configuration.fileURL! as Any)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpInitialView()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        swiftyHue.stopHeartbeat()
    }

    // MARK: - Private Funcs
    @objc func onDidLightUpdate(_ notification: Notification) {
        if let cache = swiftyHue.resourceCache {
            for light in Array(cache.lights.values) {
                for (section, groupsByType) in groups.enumerated() {
                    for (row, group) in groupsByType.enumerated()
                        where group.lightIdentifiers.contains(light.identifier) {
                        if let lightIndex = group.lights.index(where: { $0.identifier == light.identifier }) {
                            self.groups[section][row].lights[lightIndex] = light
                        }
                    }
                }
            }
            self.fetchData(group: nil, completion: nil)
        }
    }

    private func setUpInitialView() {
        // Checks if current bridge has changed if true
        // it starts HB and reloads data otherwise it just restarts HB
        // ip, bridge, sh are passed by reference so objects in this class are mutated
        let swiftyHueDidChange = RGBRequest.shared.getSwiftyHueWithBool()
        if swiftyHueDidChange.didIpChange || groups.isEmpty {
            swiftyHue = swiftyHueDidChange.swiftyHue
            fetchData(group: nil, completion: {
                self.swiftyHue.startHeartbeat()
                self.tableView.reloadData()
            })
        } else {
            fetchData(group: nil, completion: {
                self.swiftyHue.startHeartbeat()
                if self.tableView.numberOfRows(inSection: 0) != self.groups[0].count ||
                    self.tableView.numberOfRows(inSection: 1) != self.groups[1].count {
                    self.tableView.reloadData()
                }
            })
        }
    }

    // Fetch all groups and lights and update cells
    private func fetchData(group: RGBGroup?, completion: (() -> Void)?) {
        RGBRequest.shared.getGroups(with: self.swiftyHue, completion: { (groups, error) in
            guard error == nil, let groups = groups else {
                RGBRequest.shared.errorsFromResponse(error: error, completion: {
                    self.setUpInitialView()
                })
                return
            }
            self.groups = groups
            self.updateUI(group)
            completion?()
        })
    }

    private func updateUI(_ group: RGBGroup?) {
        for (section, groupsByType) in groups.enumerated() {
            for (row, subGroup) in groupsByType.enumerated() where group?.identifier != subGroup.identifier {
                let cell = tableView.cellForRow(at: IndexPath(row: row, section: section)) as? LightsGroupCustomCell
                cell?.group = subGroup
            }
        }
    }

    private func updateLightsBrightnessForGroup(group: RGBGroup, value: Float) {
        for light in group.lights where light.state.on! == true {
            var lightState = LightState()
            lightState.brightness = Int(value * 2.54)
            RGBGroupsAndLightsHelper.shared.setLightState(for: light, using: swiftyHue,
                                                          with: lightState, completion: nil)
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
        }
        return "Groups"
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
        var lightState = LightState()
        lightState.on = lightGroupsTableViewCell.switch.isOn
        RGBGroupsAndLightsHelper.shared.setLightState(for: group, using: swiftyHue,
                                                      with: lightState, completion: {
            self.fetchData(group: nil, completion: nil)
        })
    }

    // Brightness slider started moving
    func lightGroupsTableViewCell(_ lightGroupTableViewCell: LightsGroupCustomCell,
                                  lightSliderStartedFor group: RGBGroup) {
        swiftyHue.stopHeartbeat()
    }

    // Brightness slider is moving
    func lightGroupsTableViewCell(_ lightGroupsTableViewCell: LightsGroupCustomCell,
                                  lightSliderMovedFor group: RGBGroup) {
        RGBGroupsAndLightsHelper.shared.sendTimeSensistiveAPIRequest(withTimeInterval: 0.25, completion: {
            self.updateLightsBrightnessForGroup(group: group, value: lightGroupsTableViewCell.slider.value)
        })
    }

    // Brightness slider stopped moving
    func lightGroupsTableViewCell(_ lightGroupTableViewCell: LightsGroupCustomCell,
                                  lightSliderEndedFor group: RGBGroup) {
        self.updateLightsBrightnessForGroup(group: group, value: lightGroupTableViewCell.slider.value)
        self.fetchData(group: group, completion: {
            self.swiftyHue.startHeartbeat()
        })
    }
}

// MARK: - Add Group Delegate
extension LightGroupsTableViewController: GroupAddDelegate {
    func groupAddedSuccess(_ name: String, _ lights: [String]) {
        swiftyHue.bridgeSendAPI.createGroupWithName(name, andType: .LightGroup,
                                                    includeLightIds: lights,
                                                    completionHandler: { _ in
                                                        self.fetchData(group: nil, completion: {
                                                            self.tableView.reloadData()
                                                        })
        })
    }
}

// MARK: - NAVIGATION
extension LightGroupsTableViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "SelectedLightGroupSegue":
            guard let lightTableViewController = segue.destination as? LightTableViewController else {
                logger.error("could not cast \(segue.destination) as LightTableViewController")
                return
            }
            guard let index = tableView.indexPathForSelectedRow else {
                logger.error("could not get index selected:",
                      "\(String(describing: tableView.indexPathForSelectedRow?.row))",
                    " from tableview.indexPathForSelectedRow?.row")
                    return
            }
            swiftyHue.stopHeartbeat()
            lightTableViewController.swiftyHue = swiftyHue
            lightTableViewController.title = groups[index.section][index.row].name
            lightTableViewController.group = groups[index.section][index.row]
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
