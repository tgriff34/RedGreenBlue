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

        RGBRequest.setBridgeConfiguration(for: rgbBridge, with: swiftyHue)

        tableView.estimatedRowHeight = 600
        tableView.rowHeight = UITableView.automaticDimension

        swiftyHue.setLocalHeartbeatInterval(3, forResourceType: .groups)
        swiftyHue.setLocalHeartbeatInterval(3, forResourceType: .lights)

        NotificationCenter
            .default
            .addObserver(self,
                         selector: #selector(onDidGroupUpdate(_:)),
                         name: NSNotification.Name(rawValue: ResourceCacheUpdateNotification.groupsUpdated.rawValue),
                         object: nil)
        NotificationCenter
            .default
            .addObserver(self,
                         selector: #selector(onDidLightUpdate(_:)),
                         name: NSNotification.Name(rawValue: ResourceCacheUpdateNotification.lightsUpdated.rawValue),
                         object: nil)

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add,
                                                            target: self, action: #selector(addGroup))

        fetchGroupsAndLights {
            self.tableView.reloadData()
            self.updateCells(ignoring: nil, from: self.CACHE_KEY, completion: nil)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.updateCells(ignoring: nil, from: API_KEY, completion: {
            self.swiftyHue.startHeartbeat()
        })
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        swiftyHue.stopHeartbeat()
    }

    // MARK: - Private Funcs
    @objc func onDidGroupUpdate(_ notification: Notification) {
        if let cache = swiftyHue.resourceCache {
            self.lightGroups = cache.groups
            self.groupIdentifiers = RGBGroupsAndLightsHelper.retrieveGroupIds(from: self.lightGroups)
            print(self.groupIdentifiers)
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
                completion?()
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
                    continue
            }

            guard let group = self.lightGroups[groupIdentifier] else {
                print("Error getting group at lightGroups[groupIdentifier]")
                continue
            }

            let (averageBrightnessOfLightsOn, numberOfLightsOn) = getAverageBrightnessAndNumberOfLightsOn(from: group)

            numberOfLightsOn > 0 ? cell.switch.setOn(true, animated: true) : cell.switch.setOn(false, animated: true)

            cell.numberOfLightsLabel.text = self.parseNumberOfLightsOn(for: self.lightGroups[groupIdentifier]!,
                                                                       numberOfLightsOn)

            UIView.animate(withDuration: 1, animations: {
                if numberOfLightsOn > 0 {
                    cell.lightBrightnessSlider.setValue(Float(averageBrightnessOfLightsOn / numberOfLightsOn) / 2.54,
                                                        animated: true)
                } else {
                    cell.lightBrightnessSlider.setValue(1, animated: true)
                }
            })
        }
    }

    func getAverageBrightnessAndNumberOfLightsOn(from group: Group) -> (Int, Int) {
        var numberOfLightsOn: Int = 0
        var averageBrightnessOfLightsOn: Int = 0
        for identifier in group.lightIdentifiers! {
            guard let state = self.allLights[identifier]?.state else {
                return (0, 0)
            }
            if state.on! == true {
                averageBrightnessOfLightsOn += state.brightness!
                numberOfLightsOn += 1
            }
        }
        return (averageBrightnessOfLightsOn, numberOfLightsOn)
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
        swiftyHue
            .bridgeSendAPI
            .setLightStateForGroupWithId(groupIdentifiers[sender.tag],
                                         withLightState: RGBGroupsAndLightsHelper.retrieveLightState(from: sender),
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

    @objc func sliderChanged(_ sender: UISlider!, _ event: UIEvent) {
        if let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
            case .began:
                print("Slider: stopping hearbeat")
                swiftyHue.stopHeartbeat()
            case .moved:
                RGBGroupsAndLightsHelper.sendTimeSensistiveAPIRequest {
                    self.updateLightsBrightnessForGroup(at: sender.tag, with: sender.value)
                }
            case .ended:
                self.updateLightsBrightnessForGroup(at: sender.tag, with: sender.value)
                print("Slider: \(sender.tag) \(sender.value)")
                self.updateCells(ignoring: self.groupIdentifiers[sender.tag], from: self.API_KEY, completion: {
                    self.swiftyHue.startHeartbeat()
                })
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
                self.swiftyHue.bridgeSendAPI.updateLightStateForId(identifier, withLightState: lightState,
                                                                   transitionTime: nil, completionHandler: { _ in })
            }
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

            let menu = UIAlertController(title: lightGroups[groupIdentifiers[indexPath.row]]?.name,
                                         message: nil, preferredStyle: .actionSheet)

            let deleteAction = UIAlertAction(title: "Delete Group", style: .destructive, handler: { _ in
                self.swiftyHue.bridgeSendAPI.removeGroupWithId(self.groupIdentifiers[indexPath.row],
                                                               completionHandler: { _ in
                                                                self.deleteRowFromTableView(at: indexPath.row)
                })
            })

            let editAction = UIAlertAction(title: "Edit Group", style: .default, handler: { _ in
                guard let group = self.lightGroups[self.groupIdentifiers[indexPath.row]] else {
                    print("Error getting group from long press")
                    return
                }
                self.addOrEditView(group)
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

        let (averageBrightness, numberOfLightsOn) = getAverageBrightnessAndNumberOfLightsOn(from: group)

        cell.label.text = group.name
        cell.numberOfLightsLabel.text = parseNumberOfLightsOn(for: group, numberOfLightsOn)

        cell.switch.tag = indexPath.row
        numberOfLightsOn > 0 ? cell.switch.setOn(true, animated: false) : cell.switch.setOn(false, animated: false)
        cell.switch.addTarget(self, action: #selector(self.switchChanged(_:)), for: .valueChanged)

        cell.lightBrightnessSlider.tag = indexPath.row
        if numberOfLightsOn > 0 {
            cell.lightBrightnessSlider.setValue(Float(averageBrightness / numberOfLightsOn) / 2.54,
                                                animated: true)
        } else {
            cell.lightBrightnessSlider.setValue(1, animated: true)
        }
        cell.lightBrightnessSlider.addTarget(self, action: #selector(sliderChanged(_:_:)), for: .valueChanged)

        return cell
    }

    func deleteRowFromTableView(at row: Int) {
        fetchGroupsAndLights {
            self.tableView.beginUpdates()
            self.tableView.deleteRows(at: [IndexPath(row: row, section: 0)],
                                      with: .automatic)
            self.tableView.endUpdates()
        }
    }

    func insertRowToTableView() {
        fetchGroupsAndLights {
            self.tableView.beginUpdates()
            self.tableView.insertRows(at: [IndexPath(row: self.lightGroups.count - 1, section: 0)],
                                      with: .automatic)
            self.tableView.endUpdates()
        }
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
            lightTableViewController.rgbBridge = rgbBridge
            lightTableViewController.lightIdentifiers = lightGroups[groupIdentifiers[index]]?.lightIdentifiers
            lightTableViewController.lights = allLights
            lightTableViewController.title = lightGroups[groupIdentifiers[index]]?.name
            lightTableViewController.groupIdentifier = groupIdentifiers[index]
            lightTableViewController.group = lightGroups[groupIdentifiers[index]]

        default:
            print("Error performing segue: \(String(describing: segue.identifier))")
        }
    }

    @objc func addGroup() {
        addOrEditView(nil)
    }

    // Modularize
    func addOrEditView(_ group: Group?) {
        guard let lightGroupsAddEditViewController = storyboard?.instantiateViewController(withIdentifier: "addGroup")
            as? LightGroupsAddEditViewController else {
                print("Error could not instantiateViewController: addGroup as? LightGroupsAddEditViewController")
                return
        }
        lightGroupsAddEditViewController.group = group
        lightGroupsAddEditViewController.lights = allLights
        lightGroupsAddEditViewController.swiftyHue = swiftyHue
        lightGroupsAddEditViewController.name = group?.name ?? ""
        lightGroupsAddEditViewController.selectedLights = group?.lightIdentifiers ?? []
        let navigationController = UINavigationController(rootViewController: lightGroupsAddEditViewController)

        present(navigationController, animated: true, completion: nil)

        lightGroupsAddEditViewController.onSave = { (result) in
            if result {
                self.insertRowToTableView()
            }
        }
    }
}
