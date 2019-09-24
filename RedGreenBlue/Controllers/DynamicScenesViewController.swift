//
//  DynamicScenesViewController.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 9/9/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import Foundation
import UIKit
import SwiftyHue
import BTNavigationDropdownMenu

class DynamicScenesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var swiftyHue: SwiftyHue!
    var groups = [RGBGroup]()
    var dynamicScenes = [RGBDynamicScene]()
    var navigationItems = [String]()

    var selectedGroupIndex = 0

    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        swiftyHue = RGBRequest.shared.getSwiftyHue()
        tableView.delegate = self
        tableView.dataSource = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        if let realm = RGBDatabaseManager.realm() {
//            RGBDatabaseManager.write(to: realm, closure: {
//                realm.add(RGBDynamicScene(name: "Test", timer: 3,
//                                          bottomBrightness: 150, upperBrightness: 150),
//                          update: .all)
//                let setting = realm.object(ofType: RGBDynamicScene.self, forPrimaryKey: "Test")
//
//                setting?.xys.append(XY([0, 1]))
//                setting?.xys.append(XY([0, 1]))
//            })
//        }
        fetchData()
    }

    // MARK: - Private Functions
    private func fetchData() {
        guard let results = RGBDatabaseManager.realm()?.objects(RGBDynamicScene.self) else {
            logger.error("could not retrieve results of RGBDynamicScenes from DB")
            return
        }
        dynamicScenes = Array(results)

        RGBRequest.shared.getGroups(with: self.swiftyHue, completion: { (groups, error) in
            guard error == nil, let groups = groups else {
                logger.error(error.debugDescription)
                return
            }
            self.groups = groups
            self.navigationItems.removeAll()
            for group in groups {
                self.navigationItems.append(group.name)
            }
            self.setupDropdownNavigationBar()
        })
    }

    private func setupDropdownNavigationBar() {
        let menuView = BTNavigationDropdownMenu(title: BTTitle.index(selectedGroupIndex), items: navigationItems)
        self.navigationItem.titleView = menuView
        self.tableView.reloadData()

        menuView.menuTitleColor = .white
        menuView.cellBackgroundColor = view.backgroundColor
        menuView.cellTextLabelColor = .white
        menuView.didSelectItemAtIndexHandler = { (indexPath: Int) -> Void in
            self.selectedGroupIndex = indexPath
        }
    }

    private func setScene(scene: RGBDynamicScene, previousIndices: inout [Int]) {
        var indicesUsed = [Int]()
        for (index, light) in self.groups[self.selectedGroupIndex].lights.enumerated() {
            // Create lightstate and turn light on
            var lightState = LightState()
            lightState.on = true

            // Set brightness for light within random range of upper / lower bounds

            // Set xy color value to random xy in array without repeating same color
            var randomNumber = Int(arc4random_uniform(UInt32(scene.xys.count)))
            if indicesUsed.count < scene.xys.count {
                while indicesUsed.contains(randomNumber) {
                    randomNumber = Int(arc4random_uniform(UInt32(scene.xys.count)))
                }
            }
            previousIndices[index] = randomNumber
            indicesUsed.append(randomNumber)

            lightState.xy = [scene.xys[randomNumber].xvalue, scene.xys[randomNumber].yvalue]

            RGBGroupsAndLightsHelper.shared.setLightState(for: light, using: self.swiftyHue,
                                                          with: lightState, completion: nil)
        }
    }
}

// MARK: - TableView
extension DynamicScenesViewController {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dynamicScenes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DynamicScenesCellIdentifier")
            as! LightsDynamicSceneCustomCell // swiftlint:disable:this force_cast
        cell.dynamicScene = dynamicScenes[indexPath.row]
        cell.delegate = self
        return cell
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        return nil
    }
}

// MARK: - Cell Delegate
var timer: Timer?

extension DynamicScenesViewController: DynamicSceneCellDelegate {
    func dynamicSceneTableView(_ dynamicTableViewCell: LightsDynamicSceneCustomCell,
                               sceneSwitchTappedFor scene: RGBDynamicScene) {
        // Set selected row to current cell
        if dynamicTableViewCell.switch.isOn {
            timer?.invalidate()
            tableView.selectRow(at: IndexPath(row: dynamicScenes.index(of: scene)!, section: 0),
                                animated: true, scrollPosition: .none)

            // Remove previous scene timer and reset indices
            var previousIndices = [Int](repeating: -1, count: groups[selectedGroupIndex].lights.count)

            // Set scene
            setScene(scene: scene, previousIndices: &previousIndices)
            timer = Timer.scheduledTimer(withTimeInterval: scene.timer, repeats: true, block: { _ in
                self.setScene(scene: scene, previousIndices: &previousIndices)
            })
        } else {
            timer?.invalidate()
            timer = nil
        }
    }
}
