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

    var lights: [String: Light]?
    var lightIdentifiers: [String]?
    var swiftyHue: SwiftyHue?

    override func viewDidLoad() {
        super.viewDidLoad()

        APIFetchRequest.fetchAllLights(swiftyHue: swiftyHue!, completion: { (lights) in
            self.lights = lights
            self.tableView.reloadData()
        })
    }

    @objc func switchChanged(_ sender: UISwitch!) {
        var lightState = LightState()

        if sender.isOn {
            lightState.on = true
        } else {
            lightState.on = false
        }

        swiftyHue?.bridgeSendAPI.updateLightStateForId(lightIdentifiers![sender.tag],
                                                       withLightState: lightState, completionHandler: { _ in
            return
        })
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "LightsCellIdentifier")!

        guard let light = lights?[lightIdentifiers![indexPath.row]] else {
            print("Error could not retrieve light from lights group")
            return cell
        }

        cell.textLabel?.text = light.name

        let switchView = UISwitch(frame: .zero)
        switchView.tag = indexPath.row
        switchView.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)
        switchView.setOn(light.state.on! ? true : false, animated: true)

        cell.accessoryView = switchView

        return cell
    }
}
