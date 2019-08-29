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

    private let API_KEY: String = "API_KEY" //swiftlint:disable:this identifier_name
    private let CACHE_KEY: String = "CACHE_KEY" //swiftlint:disable:this identifier_name

    var groupIdentifier: String?
    var group: Group?
    var lights: [String: Light]?
    var lightIdentifiers: [String]?
    var rgbBridge: RGBHueBridge?

    let swiftyHue = SwiftyHue()

    @IBOutlet weak var tableView: UITableView!
    var navigationSwitch: UISwitch?

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 400
        tableView.rowHeight = UITableView.automaticDimension

        guard let rgbBridge = rgbBridge else {
            return
        }

        RGBRequest.setBridgeConfiguration(for: rgbBridge, with: swiftyHue)

        swiftyHue.setLocalHeartbeatInterval(3, forResourceType: .lights)

        NotificationCenter
            .default
            .addObserver(self,
                         selector: #selector(onDidLightUpdate(_:)),
                         name: NSNotification.Name(rawValue: ResourceCacheUpdateNotification.lightsUpdated.rawValue),
                         object: nil)

        setupNavigationSwitch()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        updateCells(from: API_KEY, completion: {
            self.swiftyHue.startHeartbeat()
        })
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        swiftyHue.stopHeartbeat()
    }

    // MARK: - Private funcs
    @objc func onDidLightUpdate(_ notification: Notification) {
        if let cache = swiftyHue.resourceCache {
            self.lights = cache.lights
            updateCells(from: CACHE_KEY, completion: nil)
        }
    }

    func updateCells(from KEY: String, completion: (() -> Void)?) {
        switch KEY {
        case API_KEY:
            RGBRequest.getLights(with: self.swiftyHue, completion: { (lights) in
                self.lights = lights
                self.navigationSwitch?.setOn(self.ifAnyLightsAreOnInGroup(), animated: true)
                self.updateCellsToScreen()
                completion?()
            })
        case CACHE_KEY:
            self.navigationSwitch?.setOn(self.ifAnyLightsAreOnInGroup(), animated: true)
            updateCellsToScreen()
        default:
            break
        }
    }

    func updateCellsToScreen() {
        for identifier in lightIdentifiers! {
            guard let cell = tableView.cellForRow(at: IndexPath(row: lightIdentifiers!.index(of: identifier)!,
                                                                section: 0)) as? LightsCustomCell else {
                                                                    return
            }

            guard let lightState = lights?[identifier]?.state else {
                return
            }

            cell.switch.setOn(lightState.on!, animated: true)
            if lightState.on! {
                UIView.animate(withDuration: 1, animations: {
                    cell.slider.setValue(Float(lightState.brightness!) / 2.54, animated: true)
                })
            } else {
                UIView.animate(withDuration: 1, animations: {
                    cell.slider.setValue(1, animated: true)
                })
            }
        }
    }

    @objc func navigationSwitchChanged(_ sender: UISwitch!) {
        guard let groupIdentifier = self.groupIdentifier else {
            print("Error retrieving groupIdentifier")
            return
        }
        swiftyHue
            .bridgeSendAPI
            .setLightStateForGroupWithId(groupIdentifier,
                                         withLightState: RGBGroupsAndLightsHelper.retrieveLightState(from: sender),
                                         completionHandler: { (error) in
                                            guard error == nil else {
                                                print("Error setLightStateForGroupWithId: ",
                                                      String(describing: error?.description))
                                                return
                                            }
                                            self.updateCellsFromNavigationSwitch(with:
                                                RGBGroupsAndLightsHelper.retrieveLightState(from: sender))
        })
    }

    func updateCellsFromNavigationSwitch(with lightState: LightState) {
        for identifier in lightIdentifiers! {
            guard let cell = tableView.cellForRow(at: IndexPath(row: lightIdentifiers!.index(of: identifier)!,
                                                                section: 0)) as? LightsCustomCell else {
                                                                    return
            }
            cell.switch.setOn(lightState.on!, animated: true)
            updateCells(from: API_KEY, completion: nil)
        }
    }

    @objc func cellSwitchChanged(_ sender: UISwitch!) {
        swiftyHue
            .bridgeSendAPI
            .updateLightStateForId(lightIdentifiers![sender.tag],
                                   withLightState: RGBGroupsAndLightsHelper.retrieveLightState(from: sender),
                                   completionHandler: { (error) in
                                    guard error == nil else {
                                        print("Error sending setLightStateForGroupWithId:",
                                              "\(String(describing: error?.description))")
                                        return
                                    }
                                    self.updateCells(from: self.API_KEY, completion: nil)
        })
    }
    @objc func sliderChanged(_ sender: UISlider!, _ event: UIEvent) {
        if let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
            case .began:
                print("Slider began")
                swiftyHue.stopHeartbeat()
            case .moved:
                RGBGroupsAndLightsHelper.sendTimeSensistiveAPIRequest {
                    self.setBrightnessForLight(at: sender.tag, with: sender.value)
                }
            case .ended:
                print("Slider ended")
                self.setBrightnessForLight(at: sender.tag, with: sender.value)
                updateCells(from: API_KEY, completion: {
                    self.swiftyHue.startHeartbeat()
                })
            default:
                break
            }
        }
    }

    func setBrightnessForLight(at index: Int, with value: Float) {
        var lightState = LightState()
        lightState.brightness = Int(value * 2.54)
        print(self.lightIdentifiers![index])
        self.swiftyHue
            .bridgeSendAPI
            .updateLightStateForId(self.lightIdentifiers![index],
                                   withLightState: lightState,
                                   transitionTime: nil,
                                   completionHandler: { (error) in
                                    guard error == nil else {
                                        print("Error updateLightStateForId in sliderChange(_:_:) - ",
                                              String(describing: error?.description))
                                        return
                                    }
        })
    }

    func setupNavigationSwitch() {
        navigationSwitch = UISwitch(frame: .zero)
        navigationSwitch?.addTarget(self, action: #selector(navigationSwitchChanged(_:)), for: .valueChanged)
        navigationSwitch?.setOn(ifAnyLightsAreOnInGroup(), animated: true)

        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: navigationSwitch!)
    }

    func ifAnyLightsAreOnInGroup() -> Bool {
        if RGBGroupsAndLightsHelper.getNumberOfLightsOnInGroup(lightIdentifiers!, lights!) > 0 {
            return true
        }
        return false
    }
}

// MARK: - Tableview
extension LightTableViewController {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let count = lightIdentifiers?.count else {
            print("Error retrieving lightIdentifiers?.count - returning 0")
            return 0
        }
        return count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //swiftlint:disable:next force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: "LightsCellIdentifier") as! LightsCustomCell

        guard let light = lights?[lightIdentifiers![indexPath.row]] else {
            print("Error could not retrieve light from lights group")
            return cell
        }

        cell.label.text = light.name
        cell.switch.tag = indexPath.row
        cell.switch.addTarget(self, action: #selector(cellSwitchChanged(_:)), for: .valueChanged)
        cell.switch.setOn(light.state.on! ? true : false, animated: true)

        cell.slider.addTarget(self, action: #selector(sliderChanged(_:_:)), for: .valueChanged)
        cell.slider.tag = indexPath.row
        if light.state.on! {
            cell.slider.value = Float(light.state.brightness!) / 2.54
        } else {
            cell.slider.value = 1
        }

        return cell
    }
}

// MARK: - Navigation
extension LightTableViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "SingleLightColorPickerSegue":
            guard let colorPickerViewController = segue.destination as? ColorPickerViewController,
                let index = tableView.indexPathForSelectedRow?.row else {
                    print("Error could not cast \(segue.destination) as LightTableViewController")
                    print("Error could not get index selected:",
                          "\(String(describing: tableView.indexPathForSelectedRow?.row))",
                        " from tableview.indexPathForSelectedRow?.row")
                    return
            }
            guard let light = lights![lightIdentifiers![index]] else {
                return
            }

            colorPickerViewController.lightState = light.state
            colorPickerViewController.title = light.name
            colorPickerViewController.swiftyHue = swiftyHue
            colorPickerViewController.lights = [lightIdentifiers![index]: light]
        case "GroupColorPickerSegue":
            guard let colorPickerViewController = segue.destination as? ColorPickerViewController else {
                print("Error could not cast \(segue.destination) as LightTableViewController")
                return
            }

            var groupLights = [String: Light]()
            for identifier in lightIdentifiers! {
                groupLights[identifier] = lights![identifier]
            }

            colorPickerViewController.lightState = group?.action
            colorPickerViewController.title = group?.name
            colorPickerViewController.swiftyHue = swiftyHue
            colorPickerViewController.lights = groupLights
            colorPickerViewController.lightIdentifiers = lightIdentifiers
        default:
            print("Error performing segue: \(String(describing: segue.identifier))")
        }
    }
}
