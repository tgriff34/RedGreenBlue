//
//  LightTableViewController.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 8/17/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import UIKit
import SwiftyHue

class LightTableViewController: UITableViewController {

    var groupIdentifier: String?
    var lights: [String: Light]?
    var lightIdentifiers: [String]?
    var swiftyHue: SwiftyHue?

    var navigationSwitch: UISwitch?

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.estimatedRowHeight = 400
        tableView.rowHeight = UITableView.automaticDimension

        setupNavigationSwitch()
    }

    @objc func navigationSwitchChanged(_ sender: UISwitch!) {
        guard let groupIdentifier = self.groupIdentifier else {
            print("Error retrieving groupIdentifier")
            return
        }
        swiftyHue?
            .bridgeSendAPI
            .setLightStateForGroupWithId(groupIdentifier,
                                         withLightState: RGBGroupsAndLightsHelper.retrieveLightState(from: sender),
                                         completionHandler: { (error) in
                                            guard error == nil else {
                                                print("Error setLightStateForGroupWithId: ",
                                                      String(describing: error?.description))
                                                return
                                            }
        })
    }

    @objc func cellSwitchChanged(_ sender: UISwitch!) {
        swiftyHue?
            .bridgeSendAPI
            .updateLightStateForId(lightIdentifiers![sender.tag],
                                   withLightState: RGBGroupsAndLightsHelper.retrieveLightState(from: sender),
                                   completionHandler: { (error) in
                                    guard error == nil else {
                                        print("Error sending setLightStateForGroupWithId:",
                                              "\(String(describing: error?.description))")
                                        return
                                    }
                                    RGBRequest.getLights(with: self.swiftyHue!, completion: { (lights) in
                                        self.lights = lights
                                        self.navigationSwitch?.setOn(self.ifAnyLightsAreOnInGroup(), animated: true)
                                    })
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
                print("Slider began")
            case .moved:
                guard previousTimer == nil else { return }
                previousTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false, block: { _ in
                    self.setBrightnessForLight(at: sender.tag, with: sender.value)
                })
            case .ended:
                print("Slider ended")
            default:
                break
            }
        }
    }

    func setBrightnessForLight(at index: Int, with value: Float) {
        var lightState = LightState()
        lightState.brightness = Int(value * 2.54)
        print(self.lightIdentifiers![index])
        self.swiftyHue?
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
                                    self.previousTimer = nil
        })
    }

    func setupNavigationSwitch() {
        navigationSwitch = UISwitch(frame: .zero)
        navigationSwitch?.addTarget(self, action: #selector(navigationSwitchChanged(_:)), for: .valueChanged)
        navigationSwitch?.setOn(ifAnyLightsAreOnInGroup(), animated: true)

        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: navigationSwitch!)
    }

    func ifAnyLightsAreOnInGroup() -> Bool {
        for identifier in lightIdentifiers! {
            guard let lightState = lights?[identifier]?.state else {
                return false
            }
            if lightState.on! {
                return true
            }
        }
        return false
    }
}

extension LightTableViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let count = lightIdentifiers?.count else {
            print("Error retrieving lightIdentifiers?.count - returning 0")
            return 0
        }
        return count
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
        cell.slider.value = Float(light.state.brightness!) / 2.54
        cell.slider.tag = indexPath.row

        return cell
    }
}
