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
    var groupIdentifiers: [String] = []
    var groups: [String: Any] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {

        guard let rgbBridge = rgbBridge else {
            return
        }

        let bridgeAccessConfig = BridgeAccessConfig(bridgeId: "BridgeId",
                                                    ipAddress: rgbBridge.ipAddress,
                                                    username: rgbBridge.username)

        let swiftyHue = SwiftyHue()
        swiftyHue.setBridgeAccessConfig(bridgeAccessConfig)

        let resourceAPI = swiftyHue.resourceAPI
        resourceAPI.fetchGroups({ (result) in
            guard let groups = result.value else {
                return
            }

            self.groups = groups

            for group in groups {
                self.groupIdentifiers.append(group.key)
                print("LightsGroupTableViewController: \(group.value.name)")
            }
            print("LightsGroupTableViewController: HERE")
            self.tableView.reloadData()
        })
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groups.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // swiftlint:disable:next force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: "GroupsCellIdentifier") as! LightsGroupCustomCell

        guard let group = groups[groupIdentifiers[indexPath.row]] as? Group else {
            print("could not cast to a group")
            return cell
        }

        print("LightsGroupTableViewController: \(group)")

        cell.label.text = group.name

        return cell
    }
}
