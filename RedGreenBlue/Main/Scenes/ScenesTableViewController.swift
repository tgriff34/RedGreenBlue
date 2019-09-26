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

    var selectedGroupIndex = 0

    var navigationItems = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()
        swiftyHue = RGBRequest.shared.getSwiftyHue()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        RGBRequest.shared.setUpConnectionListeners()
        fetchData()
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
        let menuView = BTNavigationDropdownMenu(title: BTTitle.index(selectedGroupIndex), items: navigationItems)
        self.navigationItem.titleView = menuView
        self.tableView.reloadData()

        menuView.cellBackgroundColor = view.backgroundColor
        if #available(iOS 13, *) {
            menuView.menuTitleColor = UIColor.label
            menuView.arrowTintColor = UIColor.label
            menuView.cellTextLabelColor = UIColor.label
        } else {
            menuView.menuTitleColor = .black
            menuView.arrowTintColor = .black
            menuView.cellTextLabelColor = .black
        }
        menuView.didSelectItemAtIndexHandler = { (indexPath: Int) -> Void in
            self.selectedGroupIndex = indexPath
            self.tableView.reloadData()
        }
    }
}

extension ScenesTableViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if allScenes.isEmpty {
            return 0
        }
        return allScenes[selectedGroupIndex].count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //swiftlint:disable:next force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: "ScenesCellIdentifier") as! LightSceneCustomCell
        cell.label.text = allScenes[selectedGroupIndex][indexPath.row].name
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        swiftyHue.bridgeSendAPI
            .recallSceneWithIdentifier(allScenes[selectedGroupIndex][indexPath.row].identifier,
                                       inGroupWithIdentifier: allScenes[selectedGroupIndex][indexPath.row].group,
                                       completionHandler: { (error) in
                                         guard error == nil else {
                                             logger.warning("recallSceneWithIdentifier ",
                                                            String(describing: error?.description))
                                             return
                                         }
            })
    }
}
