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
    @IBOutlet weak var groupBrightnessSlider: UISlider!

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 400
        tableView.rowHeight = UITableView.automaticDimension

        NotificationCenter.default.addObserver(self, selector: #selector(onDidLightUpdate(_:)),
                                               name: NSNotification.Name(rawValue:
                                                ResourceCacheUpdateNotification.lightsUpdated.rawValue),
                                               object: nil)
        setupNavigationSwitch()
        groupBrightnessSlider.addTarget(self, action: #selector(groupSliderChanged(_:_:)), for: .valueChanged)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        RGBRequest.shared.setUpConnectionListeners()
        self.navigationSwitch?.setOn(self.ifAnyLightsAreOnInGroup(), animated: true)
        self.setupGroupBrightnessSlider()
        self.swiftyHue.startHeartbeat()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        swiftyHue.stopHeartbeat()
    }

    // MARK: - Private funcs
    @objc func onDidLightUpdate(_ notification: Notification) {
        if let cache = swiftyHue.resourceCache {
            for light in Array(cache.lights.values) {
                if let lightIndex = group.lights.index(where: { $0.identifier == light.identifier }) {
                    self.group.lights[lightIndex] = light
                }
            }
            self.fetchData(group: nil, completion: nil)
        }
    }

    func fetchData(group: RGBGroup?, completion: (() -> Void)?) {
        guard let group = group else {
            self.updateUI(group: self.group)
            return
        }
        RGBRequest.shared.getGroup(with: group.identifier, using: self.swiftyHue, completion: { (group) in
            self.group = group
            self.updateUI(group: group)
        })
    }

    private func updateUI(group: RGBGroup) {
        for (index, light) in group.lights.enumerated() {
            guard let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? LightsCustomCell else {
                logger.error("Error getting cellForRow: \(index)")
                return
            }
            cell.light = light
        }
        navigationSwitch?.setOn(self.ifAnyLightsAreOnInGroup(), animated: true)
        setupGroupBrightnessSlider()
    }

    @objc func navigationSwitchChanged(_ sender: UISwitch!) {
        var lightState = LightState()
        lightState.on = sender.isOn
        RGBGroupsAndLightsHelper.shared.setLightState(for: group, using: swiftyHue, with: lightState, completion: {
            self.updateCellsFromNavigationSwitch(lightState)
            self.fetchData(group: self.group, completion: nil)
        })
    }

    @objc func groupSliderChanged(_ sender: UISlider!, _ event: UIEvent) {
        if let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
            case .began:
                swiftyHue.stopHeartbeat()
            case .moved:
                RGBGroupsAndLightsHelper.shared.sendTimeSensistiveAPIRequest(withTimeInterval: 0.25, completion: {
                    self.setBrightnessForGroup(group: self.group, value: sender.value)
                })
            case .ended:
                setBrightnessForGroup(group: group, value: sender.value)
                self.fetchData(group: group, completion: {
                    self.swiftyHue.startHeartbeat()
                })
            default:
                break
            }
        }
    }

    private func updateCellsFromNavigationSwitch(_ lightState: LightState) {
        for identifier in group.lightIdentifiers {
            guard let cell = tableView.cellForRow(at: IndexPath(row: group.lightIdentifiers.index(of: identifier)!,
                                                                section: 0)) as? LightsCustomCell else {
                logger.error("error getting cellForRow at: \(group.lightIdentifiers.index(of: identifier)!)")
                return
            }
            cell.switch.setOn(lightState.on!, animated: true)
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

    private func setupNavigationSwitch() {
        navigationSwitch = UISwitch(frame: .zero)
        navigationSwitch?.addTarget(self, action: #selector(navigationSwitchChanged(_:)), for: .valueChanged)
        navigationSwitch?.setOn(ifAnyLightsAreOnInGroup(), animated: true)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: navigationSwitch!)
    }

    private func setupGroupBrightnessSlider() {
        if ifAnyLightsAreOnInGroup() {
            let avgBrightness = RGBGroupsAndLightsHelper.shared.getAverageBrightnessOfLightsInGroup(group.lights)
            let numOfLightsOn = RGBGroupsAndLightsHelper.shared.getNumberOfLightsOnInGroup(group.lights)
            groupBrightnessSlider.setValue(Float(avgBrightness / numOfLightsOn) / 2.54, animated: true)
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
            self.fetchData(group: self.group, completion: nil)
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
        default:
            logger.error("Error performing segue: \(String(describing: segue.identifier))")
        }
    }
}
