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
    var groups = [RGBGroup]()
    let swiftyHue = SwiftyHue()

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.estimatedRowHeight = 600
        tableView.rowHeight = UITableView.automaticDimension

        NotificationCenter
            .default
            .addObserver(self,
                         selector: #selector(onDidLightUpdate(_:)),
                         name: NSNotification.Name(rawValue: ResourceCacheUpdateNotification.lightsUpdated.rawValue),
                         object: nil)

        RGBRequest.shared.setUpConnectionListeners()

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add,
                                                            target: self, action: #selector(addOrEditGroup))

    }

    override func viewWillAppear(_ animated: Bool) {
        let ipAddress = UserDefaults.standard.object(forKey: "DefaultBridge") as? String
        rgbBridge = RGBDatabaseManager.realm()?.object(ofType: RGBHueBridge.self, forPrimaryKey: ipAddress)

        guard let rgbBridge = rgbBridge else {
            return
        }
        print(rgbBridge.username)

        RGBRequest.shared.setBridgeConfiguration(for: rgbBridge, with: swiftyHue)

        swiftyHue.setLocalHeartbeatInterval(3, forResourceType: .lights)
        RGBRequest.shared.getGroups(with: self.swiftyHue, completion: { (groups) in
            self.groups = groups
            self.tableView.reloadData()
            self.swiftyHue.startHeartbeat()
        })
    }

    override func viewWillDisappear(_ animated: Bool) {
        swiftyHue.stopHeartbeat()
    }

    // MARK: - Private Funcs
    @objc func onDidLightUpdate(_ notification: Notification) {
        if let cache = swiftyHue.resourceCache {
            for light in Array(cache.lights.values) {
                for (groupIndex, group) in groups.enumerated() where group.lightIdentifiers.contains(light.identifier) {
                    if let lightIndex = group.lights.index(where: { $0.identifier == light.identifier }) {
                        self.groups[groupIndex].lights[lightIndex] = light
                    }
                }
            }
            self.fetchData(group: nil, completion: nil)
        }
    }

    // Fetch all groups and lights and update cells
    func fetchData(group: RGBGroup?, completion: (() -> Void)?) {
        RGBRequest.shared.getGroups(with: self.swiftyHue, completion: { (groups) in
            self.groups = groups
            self.updateUI(group)
            completion?()
        })
    }

    func updateUI(_ group: RGBGroup?) {
        for (index, subGroup) in groups.enumerated() where group?.identifier != subGroup.identifier {
            guard let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0))
                as? LightsGroupCustomCell else { return }
            cell.group = subGroup
        }
    }

    func updateLightsBrightnessForGroup(group: RGBGroup, value: Float) {
        for light in group.lights where light.state.on! == true {
            var lightState = LightState()
            lightState.brightness = Int(value * 2.54)
            RGBGroupsAndLightsHelper.shared.setLightState(for: light, using: swiftyHue,
                                                          with: lightState, completion: nil)
        }
    }

    @IBAction func showEditDeleteMenu(_ gestureRecognizer: UILongPressGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began:
            let point = gestureRecognizer.location(in: self.tableView)
            guard let indexPath = self.tableView.indexPathForRow(at: point) else {
                print("Error get long press indexPath at point: ", point)
                return
            }

            let menu = UIAlertController(title: groups[indexPath.row].name,
                                         message: nil, preferredStyle: .actionSheet)

            let deleteAction = UIAlertAction(title: "Delete Group", style: .destructive, handler: { _ in
                self.swiftyHue.bridgeSendAPI.removeGroupWithId(self.groups[indexPath.row].identifier,
                                                               completionHandler: { _ in
                                                                self.deleteRowFromTableView(at: indexPath.row)
                })
            })

            let editAction = UIAlertAction(title: "Edit Group", style: .default, handler: { _ in
                self.addOrEditView(self.groups[indexPath.row])
            })

            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
                menu.dismiss(animated: true, completion: nil)
            })

            menu.addAction(editAction)
            menu.addAction(deleteAction)
            menu.addAction(cancelAction)

            present(menu, animated: true, completion: nil)
        default:
            break
        }
    }
}

// MARK: - TABLEVIEW
extension LightGroupsTableViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groups.count
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell,
                            forRowAt indexPath: IndexPath) {
        cell.contentView.layer.masksToBounds = true
        let radius = cell.contentView.layer.cornerRadius
        cell.layer.shadowPath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: radius).cgPath
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // swiftlint:disable:next force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: "GroupsCellIdentifier") as! LightsGroupCustomCell
        cell.group = groups[indexPath.row]
        cell.delegate = self
        return cell
    }

    func deleteRowFromTableView(at row: Int) {
        fetchData(group: nil, completion: {
            self.tableView.beginUpdates()
            self.tableView.deleteRows(at: [IndexPath(row: row, section: 0)],
                                      with: .automatic)
            self.tableView.endUpdates()
        })
    }
}

extension LightGroupsTableViewController: LightsGroupsCellDelegate {
    func lightGroupsTableViewCell(_ lightGroupsTableViewCell: LightsGroupCustomCell,
                                  lightSwitchTappedFor group: RGBGroup) {
        var lightState = LightState()
        lightState.on = lightGroupsTableViewCell.switch.isOn
        RGBGroupsAndLightsHelper.shared.setLightState(for: group, using: swiftyHue,
                                                      with: lightState, completion: {
            self.fetchData(group: nil, completion: nil)
        })
    }

    func lightGroupsTableViewCell(_ lightGroupTableViewCell: LightsGroupCustomCell,
                                  lightSliderStartedFor group: RGBGroup) {
        swiftyHue.stopHeartbeat()
    }

    func lightGroupsTableViewCell(_ lightGroupsTableViewCell: LightsGroupCustomCell,
                                  lightSliderMovedFor group: RGBGroup) {
        RGBGroupsAndLightsHelper.shared.sendTimeSensistiveAPIRequest {
            self.updateLightsBrightnessForGroup(group: group, value: lightGroupsTableViewCell.slider.value)
        }
    }

    func lightGroupsTableViewCell(_ lightGroupTableViewCell: LightsGroupCustomCell,
                                  lightSliderEndedFor group: RGBGroup) {
        self.updateLightsBrightnessForGroup(group: group, value: lightGroupTableViewCell.slider.value)
        self.fetchData(group: group, completion: {
            self.swiftyHue.startHeartbeat()
        })
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
            swiftyHue.stopHeartbeat()
            lightTableViewController.swiftyHue = swiftyHue
            lightTableViewController.title = groups[index].name
            lightTableViewController.group = groups[index]

        default:
            print("Error performing segue: \(String(describing: segue.identifier))")
        }
    }

    @objc func addOrEditGroup() {
        addOrEditView(nil)
    }

    // Modularize
    func addOrEditView(_ group: RGBGroup?) {
        guard let lightGroupsAddEditViewController = storyboard?.instantiateViewController(withIdentifier: "addGroup")
            as? LightGroupsAddEditViewController else {
                print("Error could not instantiateViewController: addGroup as? LightGroupsAddEditViewController")
                return
        }
        lightGroupsAddEditViewController.group = group
        lightGroupsAddEditViewController.swiftyHue = swiftyHue
        lightGroupsAddEditViewController.name = group?.name ?? ""
        lightGroupsAddEditViewController.selectedLights = group?.lightIdentifiers ?? []
        let navigationController = UINavigationController(rootViewController: lightGroupsAddEditViewController)
        navigationController.navigationBar.barStyle = .black

        present(navigationController, animated: true, completion: nil)

        lightGroupsAddEditViewController.onSave = { (result) in
            if result {
                self.fetchData(group: nil, completion: {
                    self.tableView.reloadData()
                })
            }
        }
    }
}
