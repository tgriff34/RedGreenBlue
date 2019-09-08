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
    var allScenes = [[PartialScene]]()
    var scenesForGroup = [PartialScene]()

    var navigationItems = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()
        swiftyHue = RGBRequest.shared.getSwiftyHue()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        RGBRequest.shared.setUpConnectionListeners()
        if groups.isEmpty { fetchData() }
    }

    func fetchData() {
        RGBRequest.shared.getGroups(with: self.swiftyHue, completion: { (groups, error) in
            guard error == nil else {
                logger.error(String(describing: error.debugDescription))
                return
            }
            let justGroups = groups!
            self.navigationItems.removeAll()
            for group in justGroups where group.type == .Room {
                self.groups.append(group)
                self.navigationItems.append(group.name)
            }

            self.retrieveScenesFor(groups: self.groups)
        })
    }

    func retrieveScenesFor(groups: [RGBGroup]) {
        RGBRequest.shared.getScenes(with: self.swiftyHue, completion: { (scenes, error) in
            guard error == nil, let scenes = scenes else {
                return
            }
            var justScenes = Array(scenes.values).map({ return $0 })
            justScenes.sort(by: { $0.name < $1.name })
            for group in groups {
                var scenesForGroup = [PartialScene]()
                for scene in justScenes where scene.group == group.identifier {
                    scenesForGroup.append(scene)
                }
                self.allScenes.append(scenesForGroup)
            }
            self.setUpDropdown()
        })
    }

    func setUpDropdown() {
        let menuView = BTNavigationDropdownMenu(title: BTTitle.index(0), items: navigationItems)
        self.navigationItem.titleView = menuView
        self.scenesForGroup = self.allScenes[0]
        self.tableView.reloadData()

        menuView.menuTitleColor = .white
        menuView.cellBackgroundColor = view.backgroundColor
        menuView.cellTextLabelColor = .white
        menuView.animationDuration = 0.2
        menuView.didSelectItemAtIndexHandler = { (indexPath: Int) -> Void in
            self.scenesForGroup = self.allScenes[indexPath]
            self.tableView.reloadData()
        }
    }
}

extension ScenesTableViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return scenesForGroup.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //swiftlint:disable:next force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: "ScenesCellIdentifier") as! LightSceneCustomCell
        cell.label.text = scenesForGroup[indexPath.row].name
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        swiftyHue.bridgeSendAPI.recallSceneWithIdentifier(scenesForGroup[indexPath.row].identifier,
                                                          inGroupWithIdentifier: scenesForGroup[indexPath.row].group,
                                                          completionHandler: { (error) in
                                                            guard error == nil else {
                                                                logger.warning("recallSceneWithIdentifier ",
                                                                               String(describing: error?.description))
                                                                return
                                                            }
        })
    }
}
