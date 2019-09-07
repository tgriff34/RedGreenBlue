//
//  ScenesTableViewController.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 9/7/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import Foundation
import UIKit
import SwiftyHue
import BTNavigationDropdownMenu

class ScenesTableViewController: UITableViewController {

    var swiftyHue: SwiftyHue!
    var groups = [RGBGroup]()
    var scenes = [PartialScene]()

    var navigationItems: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        swiftyHue = RGBRequest.shared.getSwiftyHue()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchData()
    }

    func fetchData() {
        RGBRequest.shared.setUpConnectionListeners()
        RGBRequest.shared.getGroups(with: self.swiftyHue, completion: { (groups, error) in
            guard error == nil else {
                return
            }
            let justGroups = groups!
            for group in justGroups where group.type == .Room {
                self.groups.append(group)
                self.navigationItems.append(group.name)
            }
            self.setUpDropdown()
        })
    }

    func retrieveScenesFor(group: RGBGroup) {
        scenes = [PartialScene]()
        RGBRequest.shared.getScenes(with: self.swiftyHue, completion: { (scenes) in
            var justScenes = Array(scenes.values).map({ return $0 })
            justScenes.sort(by: { $0.name < $1.name })
            for scene in justScenes where scene.group == group.identifier {
                self.scenes.append(scene)
            }
            self.tableView.reloadData()
        })
    }

    func setUpDropdown() {
        let menuView = BTNavigationDropdownMenu(title: "Scenes", items: navigationItems)
        self.navigationItem.titleView = menuView

        menuView.menuTitleColor = .white
        menuView.cellBackgroundColor = view.backgroundColor
        menuView.cellTextLabelColor = .white
        menuView.animationDuration = 0.2
        menuView.didSelectItemAtIndexHandler = { (indexPath: Int) -> Void in
            self.retrieveScenesFor(group: self.groups[indexPath])
        }
    }
}

extension ScenesTableViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return scenes.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //swiftlint:disable:next force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: "ScenesCellIdentifier") as! LightSceneCustomCell
        cell.label.text = scenes[indexPath.row].name
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        swiftyHue.bridgeSendAPI.recallSceneWithIdentifier(scenes[indexPath.row].identifier,
                                                          inGroupWithIdentifier: scenes[indexPath.row].group,
                                                          completionHandler: { (error) in
                                                            print(String(describing: error?.description))
        })
    }
}
