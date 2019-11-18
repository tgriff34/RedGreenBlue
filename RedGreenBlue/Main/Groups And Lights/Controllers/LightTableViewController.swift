//
//  LightTableViewController.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 8/17/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import UIKit
import SwiftyHue

class LightTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var swiftyHue: SwiftyHue!
    var group: RGBGroup!

    @IBOutlet weak var tableView: UITableView!
    var navigationSwitch: UISwitch?
    var optionsButton: UIBarButtonItem?
    @IBOutlet weak var groupBrightnessSlider: UISlider!

    @IBOutlet weak var customScenesButton: UIButton!
    @IBOutlet weak var scenesButton: UIButton!
    // When Buttons are pushed down, make effect
    @IBAction func buttonTouchedDown(_ sender: UIButton) {
        UIButton.animate(withDuration: 0.2, animations: {
            sender.transform = CGAffineTransform.init(scaleX: 0.85, y: 0.865)
        })
    }
    // When buttons released have then transform back to normal size
    // and navigate to appropriate tab.
    @IBAction func groupsColorButton(_ sender: UIButton) {
        RGBCellUtilities.buttonPressReleased(sender, completion: {
            self.performSegue(withIdentifier: "GroupColorPickerSegue", sender: self)
        })
    }
    @IBAction func scenesButton(_ sender: UIButton) {
        RGBCellUtilities.buttonPressReleased(sender, completion: {
            self.tabBarController?.selectedViewController = self.tabBarController?.viewControllers![1]
                as? UINavigationController
            let destination = self.tabBarController?.selectedViewController as? UINavigationController
            let viewController = destination?.viewControllers.first as? ScenesTableViewController
            if let index = viewController?.groups.firstIndex(of: self.group) {
                viewController?.selectedGroupIndex = index
            }
        })
    }
    @IBAction func customScenesButton(_ sender: UIButton) {
        RGBCellUtilities.buttonPressReleased(sender, completion: {
            self.tabBarController?.selectedViewController = self.tabBarController?.viewControllers![2]
                as? UINavigationController
            let destination = self.tabBarController?.selectedViewController as? UINavigationController
            let viewController = destination?.viewControllers.first as? DynamicScenesViewController
            if let index = viewController?.groups.firstIndex(of: self.group) {
                viewController?.selectedGroupIndex = index
            }
        })
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 80
        tableView.rowHeight = UITableView.automaticDimension

        setupNavigationSwitch()
        RGBCellUtilities.setImagesForSlider(groupBrightnessSlider)
        groupBrightnessSlider.addTarget(self, action: #selector(groupSliderChanged(_:_:)), for: .valueChanged)

        if group.type != .Room {
            scenesButton.isHidden = true
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Observer for when the lights change in another app or wall switch
        NotificationCenter.default.addObserver(
            self, selector: #selector(onDidLightUpdate(_:)),
            name: NSNotification.Name(rawValue: ResourceCacheUpdateNotification.lightsUpdated.rawValue),
            object: nil)

        // If the bridge change and they were in this view, pop to group view controller

        self.fetchData(group: self.group, completion: {
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
        })

        // Set up group switch button in nav bar, and group brightness slider
        self.navigationSwitch?.setOn(self.ifAnyLightsAreOnInGroup(), animated: true)
        self.setupGroupBrightnessSlider()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Remove the observer from the notification center when navigating away.
        NotificationCenter.default.removeObserver(
            self, name: NSNotification.Name(
                rawValue: ResourceCacheUpdateNotification.lightsUpdated.rawValue),
            object: nil)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // If the user changed theme, makes sure that the labels
        // and icons change to the appropriate color
        self.tableView.reloadData()
        scenesButton.awakeFromNib()
        customScenesButton.awakeFromNib()
    }

    // MARK: - Private funcs
    @objc func onDidLightUpdate(_ notification: Notification) {
        // If the lights have change outside of the app, update the current datasource
        if let cache = swiftyHue.resourceCache {
            for light in Array(cache.lights.values) {
                if let lightIndex = group.lights.firstIndex(where: { $0.identifier == light.identifier }) {
                    self.group.lights[lightIndex] = light
                }
            }
            // Once the data source has updated, update tableview
            self.fetchData(group: self.group, completion: {
                self.tableView.beginUpdates()
                self.tableView.endUpdates()
            })
        }
    }

    // Allows you to update the UI two ways.
    // Pass in the group if something about the group has changed. (ie. # of lights, name, etc.)
    // Otherwise if group is nil, it will just update the cells with current datasource and not fetch the group.
    func fetchData(group: RGBGroup?, completion: (() -> Void)?) {
        // If the group has not been changed then no need to reload table, just update cells
        guard let group = group else {
            self.updateUI(group: self.group)
            completion?()
            return
        }
        RGBRequest.shared.getGroup(with: group.identifier, using: self.swiftyHue, completion: { (group) in
            if self.group != group { // If the group has changed just reload the entire table
                self.group = group
                self.tableView.reloadData()
                self.navigationSwitch?.setOn(self.ifAnyLightsAreOnInGroup(), animated: true)
                self.setupGroupBrightnessSlider()
            } else { // Otherwise go cell by cell for smoother UI update
                self.group = group
                self.updateUI(group: group)
            }
            completion?()
        })
    }

    // Update the cells light object with the light from the data source
    private func updateUI(group: RGBGroup) {
        for (index, light) in group.lights.enumerated() {
            let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? LightsCustomCell
            cell?.light = light
        }
        // Make sure to update the group switch and the brightness slider
        navigationSwitch?.setOn(self.ifAnyLightsAreOnInGroup(), animated: true)
        setupGroupBrightnessSlider()
    }

    // Group switch, if switched on manually all lights are on and vice versa.
    @objc func navigationSwitchChanged(_ sender: UISwitch!) {
        var lightState = LightState()
        lightState.on = sender.isOn
        RGBGroupsAndLightsHelper.shared.setLightState(for: group, using: swiftyHue, with: lightState, completion: {
            self.fetchData(group: self.group, completion: {
                self.tableView.beginUpdates()
                self.tableView.endUpdates()
            })
        })
    }

    // Show options for group. (ie. editing group lights and names, deleting group)
    @objc func optionsButtonTapped(_ sender: UIBarButtonItem) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let editAction = UIAlertAction(title: "Edit Group", style: .default, handler: { _ in
            self.performSegue(withIdentifier: "EditGroupSegue", sender: self)
        })
        let deleteAction = UIAlertAction(title: "Delete Group", style: .destructive, handler: { _ in
            self.swiftyHue.bridgeSendAPI.removeGroupWithId(self.group.identifier, completionHandler: { _ in
                self.navigationController?.popViewController(animated: true)
            })
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        actionSheet.addAction(editAction)
        actionSheet.addAction(deleteAction)
        actionSheet.addAction(cancelAction)
        if let popoverController = actionSheet.popoverPresentationController {
            popoverController.barButtonItem = sender
        }
        self.present(actionSheet, animated: true, completion: nil)
    }

    // Group slider at top of view.  If moved, all lights change to its value.
    @objc func groupSliderChanged(_ sender: UISlider!, _ event: UIEvent) {
        if let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
            case .began:
                swiftyHue.stopHeartbeat()
                self.title = "\(Int(sender.value))%"
            case .moved:
                self.title = "\(Int(sender.value))%"
                RGBGroupsAndLightsHelper.shared.sendTimeSensistiveAPIRequest(withTimeInterval: 0.25, completion: {
                    self.setBrightnessForGroup(group: self.group, value: sender.value)
                })
            case .ended:
                self.title = group.name
                setBrightnessForGroup(group: group, value: sender.value)
                self.fetchData(group: group, completion: {
                    self.swiftyHue.startHeartbeat()
                })
            default:
                break
            }
        }
    }

    private func setBrightnessForLight(light: Light, value: Float) {
        var lightState = LightState()
        lightState.brightness = Int(value * 2.54)
        RGBGroupsAndLightsHelper.shared.setLightState(for: light, using: swiftyHue, with: lightState, completion: nil)
    }

    private func setBrightnessForGroup(group: RGBGroup, value: Float) {
        for light in group.lights {
            setBrightnessForLight(light: light, value: value)
        }
    }

    // Right bar navigation items setup
    private func setupNavigationSwitch() {
        // Options button for group
        optionsButton = UIBarButtonItem(
            image: UIImage(named: "ellipsis"),
            style: .plain, target: self, action: #selector(optionsButtonTapped(_:)))

        // Group lights switch for group
        navigationSwitch = UISwitch(frame: .zero)
        navigationSwitch?.addTarget(self, action: #selector(navigationSwitchChanged(_:)), for: .valueChanged)
        navigationSwitch?.setOn(ifAnyLightsAreOnInGroup(), animated: true)

        // If the group is a 'light group' type allow the user to customize the group.
        // Any group under the 'Room' type does not allow their lights/name to be changed.
        if group.type == .LightGroup {
            navigationItem.rightBarButtonItems = [UIBarButtonItem(customView: navigationSwitch!),
                                                  optionsButton!]
        } else {
            navigationItem.rightBarButtonItems = [UIBarButtonItem(customView: navigationSwitch!)]
        }
    }

    private func setupGroupBrightnessSlider() {
        if ifAnyLightsAreOnInGroup() {
            let avgBrightness = RGBGroupsAndLightsHelper.shared.getAverageBrightnessOfLightsInGroup(group.lights)
            let numOfLightsOn = RGBGroupsAndLightsHelper.shared.getNumberOfLightsOnInGroup(group.lights)
            groupBrightnessSlider.setValue((Float(avgBrightness / numOfLightsOn) / 2.54), animated: true)
        } else {
            groupBrightnessSlider.setValue(0, animated: true)
        }
    }

    private func ifAnyLightsAreOnInGroup() -> Bool {
        if RGBGroupsAndLightsHelper.shared.getNumberOfLightsOnInGroup(group.lights) > 0 {
            return true
        }
        return false
    }
}

// MARK: - Tableview
extension LightTableViewController {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return group.lightIdentifiers.count
    }
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.contentView.layer.masksToBounds = true
        let radius = cell.contentView.layer.cornerRadius
        cell.layer.shadowPath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: radius).cgPath
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //swiftlint:disable:next force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: "LightsCellIdentifier") as! LightsCustomCell
        cell.light = group.lights[indexPath.row]
        cell.delegate = self
        return cell
    }
}

// MARK: - CellDelegate
extension LightTableViewController: LightsCellDelegate {
    // When the switch is tapped
    func lightsTableViewCell(_ lightsTableViewCell: LightsCustomCell, lightSwitchTappedFor light: Light) {
        var lightState = LightState()
        lightState.on = lightsTableViewCell.switch.isOn
        RGBGroupsAndLightsHelper.shared.setLightState(for: light, using: swiftyHue, with: lightState, completion: {
            self.fetchData(group: self.group, completion: {
                self.tableView.beginUpdates()
                self.tableView.endUpdates()
            })
        })
    }
    // Start sliding the brightness slider
    func lightsTableViewCell(_ lightsTabelViewCell: LightsCustomCell, lightSliderStartedFor light: Light) {
        swiftyHue.stopHeartbeat()
    }
    // When the brightness slider is moving
    func lightsTableViewCell(_ lightsTableViewCell: LightsCustomCell, lightSliderMovedFor light: Light) {
        RGBGroupsAndLightsHelper.shared.sendTimeSensistiveAPIRequest(withTimeInterval: 0.25, completion: {
            self.setBrightnessForLight(light: light, value: lightsTableViewCell.slider.value)
        })
    }
    // Stopped sliding the brightness slider
    func lightsTableViewCell(_ lightsTableViewCell: LightsCustomCell, lightSliderEndedFor light: Light) {
        self.setBrightnessForLight(light: light, value: lightsTableViewCell.slider.value)
        self.fetchData(group: self.group, completion: {
            self.swiftyHue.startHeartbeat()
        })
    }
}

// MARK: - Navigation
extension LightTableViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "SingleLightColorPickerSegue":
            guard let colorPickerViewController = segue.destination as? ColorPickerViewController else {
                logger.error("could not cast \(segue.destination) as LightTableViewController")
                return
            }
            guard let index = tableView.indexPathForSelectedRow?.row else {
                logger.error("could not get index selected:",
                      "\(String(describing: tableView.indexPathForSelectedRow?.row))",
                    " from tableview.indexPathForSelectedRow?.row")
                return
            }
            let light = group.lights[index]
            colorPickerViewController.title = light.name
            colorPickerViewController.swiftyHue = swiftyHue
            colorPickerViewController.lights = [light]
        case "GroupColorPickerSegue":
            guard let colorPickerViewController = segue.destination as? ColorPickerViewController else {
                logger.error("could not cast \(segue.destination) as LightTableViewController")
                return
            }
            colorPickerViewController.title = group.name
            colorPickerViewController.swiftyHue = swiftyHue
            colorPickerViewController.lights = group.lights
        case "EditGroupSegue":
            let navigationController = segue.destination as? UINavigationController
            let lightGroupsAddEditViewController = navigationController?.viewControllers.first!
                as? LightGroupsAddEditViewController
            lightGroupsAddEditViewController?.group = group
            lightGroupsAddEditViewController?.swiftyHue = swiftyHue
            lightGroupsAddEditViewController?.name = group.name
            lightGroupsAddEditViewController?.selectedLights = group.lightIdentifiers
            lightGroupsAddEditViewController?.addGroupDelegate = self
        default:
            logger.error("Error performing segue: \(String(describing: segue.identifier))")
        }
    }
}

extension LightTableViewController: GroupAddDelegate {
    func groupAddedSuccess(_ name: String, _ lights: [String]) {
        navigationItem.title = name
        swiftyHue.bridgeSendAPI.updateGroupWithId(
            group.identifier, newName: name, newLightIdentifiers: lights, completionHandler: { _ in
                self.fetchData(group: self.group, completion: {
                    self.tableView.beginUpdates()
                    self.tableView.endUpdates()
                })
        })
    }
}
