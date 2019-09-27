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
import SwiftMessages

class DynamicScenesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var swiftyHue: SwiftyHue!
    var groups = [RGBGroup]()
    var dynamicScenes: [[RGBDynamicScene]] = []
    var navigationItems = [String]()

    var selectedGroupIndex = 0

    @IBOutlet weak var tableView: UITableView!

    let realm = RGBDatabaseManager.realm()!

    override func viewDidLoad() {
        super.viewDidLoad()
        swiftyHue = RGBRequest.shared.getSwiftyHue()
        tableView.delegate = self
        tableView.dataSource = self
        fetchData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupDropdownNavigationBar()
    }

    // MARK: - Private Functions
    private func fetchData() {
        guard let results = RGBDatabaseManager.realm()?.objects(RGBDynamicScene.self).filter("isDefault = true") else {
            logger.error("could not retrieve results of RGBDynamicScenes from DB")
            return
        }
        dynamicScenes.append(Array(results))

        if let userResults = RGBDatabaseManager.realm()?.objects(RGBDynamicScene.self).filter("isDefault = false") {
            dynamicScenes.append(Array(userResults))
        } else {
            logger.warning("No user defined RGBDynamicScenes in DB")
        }
        self.tableView.reloadData()
        setupDropdownNavigationBar()
    }

    private func setupDropdownNavigationBar() {
        RGBRequest.shared.getGroups(with: self.swiftyHue, completion: { (groups, error) in
            guard error == nil, let groups = groups else {
                logger.error(error.debugDescription)
                return
            }
            self.groups = groups.flatMap({$0})
            self.navigationItems.removeAll()
            for group in self.groups {
                self.navigationItems.append(group.name)
            }
            if self.selectedGroupIndex >= self.navigationItems.count { self.selectedGroupIndex = 0 }
            let menuView = BTNavigationDropdownMenu(navigationController: self.navigationController,
                                                    containerView: self.view,
                                                    title: BTTitle.index(self.selectedGroupIndex),
                                                    items: self.navigationItems)

            self.navigationItem.titleView = menuView

            menuView.cellBackgroundColor = self.view.backgroundColor
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
            }
        })
    }

    var lightsForScene = [Int]()

    private func setScene(scene: RGBDynamicScene) {
        setLightsForScene(numberOfColors: scene.xys.count, isSequential: scene.sequentialLightChange,
                          randomColors: scene.randomColors)

        for (index, light) in self.groups[self.selectedGroupIndex].lights.enumerated() {
            // Create lightstate and turn light on
            var lightState = LightState()
            lightState.on = true

            let lightIndex = lightsForScene[index]

            lightState.xy = [scene.xys[lightIndex].xvalue, scene.xys[lightIndex].yvalue]

            RGBGroupsAndLightsHelper.shared.setLightState(for: light, using: self.swiftyHue,
                                                          with: lightState, completion: nil)
        }
    }

    private func setLightsForScene(numberOfColors: Int, isSequential: Bool, randomColors: Bool) {
        // Set lights array whether lights should be in order of them picked or randomized
        let iterator = groups[selectedGroupIndex].lights
        for _ in iterator where lightsForScene.count < iterator.count {
            if randomColors {
                lightsForScene.append(genRandomNum(numberOfColors: numberOfColors))
            } else {
                let count = iterator.count - 1
                lightsForScene = Array(repeating: 0..<numberOfColors, count: count).flatMap({$0})
                lightsForScene = Array(lightsForScene[...count])
            }
        }

        if isSequential { // If it's sequential just shift to right
            lightsForScene = lightsForScene.shiftRight()
        } else { // Otherwise randomly shuffle
            lightsForScene.shuffle()
        }
    }

    private func genRandomNum(numberOfColors: Int) -> Int {
        var randomNumber = Int(arc4random_uniform(UInt32(numberOfColors)))
        if lightsForScene.count < numberOfColors {
            while lightsForScene.contains(randomNumber) {
                randomNumber = Int(arc4random_uniform(UInt32(numberOfColors)))
            }
        }
        return randomNumber
    }
}

// MARK: - TableView
extension DynamicScenesViewController {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Default custom scenes"
        } else if section == 1 && dynamicScenes[1].count > 0 {
            return "Your custom scenes"
        }
        return ""
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dynamicScenes[section].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DynamicScenesCellIdentifier")
            as! LightsDynamicSceneCustomCell // swiftlint:disable:this force_cast
        cell.dynamicScene = dynamicScenes[indexPath.section][indexPath.row]
        cell.delegate = self
        return cell
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        return nil
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section == 0 {
            return false
        }
        return true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {
        switch editingStyle {
        case .delete:
            let sceneToDelete = realm.object(ofType: RGBDynamicScene.self,
                                             forPrimaryKey: dynamicScenes[indexPath.section][indexPath.row].name)
            RGBDatabaseManager.write(to: realm, closure: {
                // These must be deleted in this order
                realm.delete(sceneToDelete!.xys)
                realm.delete(sceneToDelete!)
            })
            dynamicScenes[indexPath.section].remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            //tableView.reloadSections(IndexSet(arrayLiteral: 1), with: .automatic)
        default:
            logger.error("editing style does not exist: \(editingStyle)")
        }
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
            guard let indexPath = tableView.indexPath(for: dynamicTableViewCell) else {
                let error = String(describing: tableView.indexPath(for: dynamicTableViewCell))
                logger.warning("could not get indexpath of cell: \(error)")
                return
            }
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)

            // Set scene
            lightsForScene.removeAll()
            setScene(scene: scene)
            timer = Timer.scheduledTimer(withTimeInterval: scene.timer, repeats: true, block: { _ in
                self.setScene(scene: scene)
            })
        } else {
            timer?.invalidate()
            timer = nil
        }
    }
}

// MARK: - Navigation
extension DynamicScenesViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "addDynamicSceneSegue":
            let navController = segue.destination as? UINavigationController
            let viewController = navController?.viewControllers.first as? DynamicScenesAddViewController
            viewController?.addSceneDelegate = self
        default:
            logger.error("error performing segue with identifier: \(segue.identifier ?? "nil")")
        }
    }
}

// MARK: - Dynamic Scene added delegate
extension DynamicScenesViewController: DynamicSceneAddDelegate {
    func dynamicSceneAdded(_ sender: DynamicScenesAddViewController, _ scene: RGBDynamicScene) {
        if dynamicScenes[1].contains(where: { $0.name == scene.name }) {
            // TODO: MODULARIZE THIS AS WELL
            let sameNameErrorMessage: MessageView = MessageView.viewFromNib(layout: .messageView)
            var sameNameErrorConfig = SwiftMessages.Config()
            sameNameErrorConfig.presentationContext = .window(windowLevel: .normal)
            sameNameErrorMessage.configureTheme(.warning)
            sameNameErrorMessage.configureContent(title: "Error Adding Scene",
                                                  body: "Name is the same as another scene!")
            sameNameErrorMessage.layoutMarginAdditions = UIEdgeInsets(top: 5, left: 20, bottom: 10, right: 20)
            sameNameErrorMessage.button?.isHidden = true
            SwiftMessages.show(config: sameNameErrorConfig, view: sameNameErrorMessage)
        } else {
            sender.dismiss(animated: true, completion: nil)
            dynamicScenes[1].append(scene)
            RGBDatabaseManager.write(to: realm, closure: {
                realm.add(scene, update: .all)
            })
            if dynamicScenes[1].count == 1 {
                tableView.reloadSections(IndexSet(arrayLiteral: 1), with: .automatic)
            } else {
                tableView.beginUpdates()
                tableView.insertRows(at: [IndexPath(row: dynamicScenes[1].count - 1, section: 1)], with: .automatic)
                tableView.endUpdates()
            }
        }
    }
}

extension Array {
    func shiftRight(amount: Int = 1) -> [Element] {
        var amount = amount
        assert(-count...count ~= amount, "Shift amount out of bounds")
        if amount < 0 { amount += count }
        return Array(self[amount ..< count] + self[0 ..< amount])
    }
}
