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
import AVFoundation

class DynamicScenesViewController: UITableViewController {

    var swiftyHue: SwiftyHue!
    var groups = [RGBGroup]()
    var dynamicScenes: [[RGBDynamicScene]] = []
    var navigationItems = [String]()

    var selectedGroupIndex = 0
    var shouldFetchDefault: Bool = true
    var selectedRowIndex: IndexPath?

    let realm = RGBDatabaseManager.realm()!

    override func viewDidLoad() {
        super.viewDidLoad()
        swiftyHue = RGBRequest.shared.getSwiftyHue()
        fetchData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupDropdownNavigationBar()
        tableView.selectRow(at: selectedRowIndex, animated: true, scrollPosition: .none)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let indexPath = tableView.indexPathForSelectedRow,
            let cell = tableView.cellForRow(at: indexPath) as? LightsDynamicSceneCustomCell,
            cell.switch.isOn {
            selectedRowIndex = tableView.indexPathForSelectedRow
        } else {
            selectedRowIndex = nil
        }
    }

    // MARK: - Private Functions
    private func fetchData() {
        guard let results = RGBDatabaseManager.realm()?.objects(RGBDynamicScene.self).filter("isDefault = true") else {
            logger.error("could not retrieve results of RGBDynamicScenes from DB")
            return
        }
        dynamicScenes.append(Array(results))

        if let userResults = RGBDatabaseManager.realm()?
            .objects(RGBDynamicScene.self)
            .filter("isDefault = false")
            .sorted(by: { $0.name > $1.name }) {
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

            if let defaultGroup = UserDefaults.standard.object(forKey: "DefaultCustomScene") as? String,
                defaultGroup != "Default", self.shouldFetchDefault {
                self.selectedGroupIndex = self.navigationItems.index(of: defaultGroup)!
            } else if self.shouldFetchDefault {
                self.selectedGroupIndex = 0
            }
            self.shouldFetchDefault = false

            let menuView = BTNavigationDropdownMenu(title: BTTitle.index(self.selectedGroupIndex),
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
}

// MARK: - TableView
extension DynamicScenesViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Default dynamic scenes"
        } else if section == 1 && dynamicScenes[1].count > 0 {
            return "Your dynamic scenes"
        }
        return ""
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dynamicScenes[section].count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DynamicScenesCellIdentifier")
            as! LightsDynamicSceneCustomCell // swiftlint:disable:this force_cast
        cell.dynamicScene = dynamicScenes[indexPath.section][indexPath.row]
        cell.delegate = self
        return cell
    }

    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if indexPath.section == 0 {
            return nil
        }
        return indexPath
    }
}

// MARK: - Cell Delegate

extension DynamicScenesViewController: DynamicSceneCellDelegate {
    func dynamicSceneTableView(_ dynamicTableViewCell: LightsDynamicSceneCustomCell,
                               sceneSwitchTappedFor scene: RGBDynamicScene) {
        guard let indexPath = tableView.indexPath(for: dynamicTableViewCell) else {
            let error = String(describing: tableView.indexPath(for: dynamicTableViewCell))
            logger.warning("could not get indexpath of cell: \(error)")
            return
        }
        // Set selected row to current cell
        if dynamicTableViewCell.switch.isOn && !groups.isEmpty {
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            selectedRowIndex = indexPath
            RGBGroupsAndLightsHelper.shared.playDynamicScene(scene: scene,
                                                             for: groups[selectedGroupIndex],
                                                             with: swiftyHue)
        } else {
            tableView.deselectRow(at: indexPath, animated: true)
            selectedRowIndex = nil
            RGBGroupsAndLightsHelper.shared.stopDynamicScene()
        }
    }
}

// MARK: - Navigation
extension DynamicScenesViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        let navController = segue.destination as? UINavigationController
        let viewController = navController?.viewControllers.first as? DynamicScenesAddViewController
        viewController?.addSceneDelegate = self

        switch segue.identifier {
        case "AddDynamicSceneSegue":
            //Handled above
            break
        case "EditDynamicSceneSegue":
            viewController?.title = "Edit Custom Scene"
            let indexPath = self.tableView.indexPathForSelectedRow
            if let cell = self.tableView.cellForRow(at: indexPath!) as? LightsDynamicSceneCustomCell,
                cell.switch.isOn {
                RGBGroupsAndLightsHelper.shared.stopDynamicScene()
                cell.switch.setOn(false, animated: true)
            }
            viewController?.scene = dynamicScenes[1][indexPath!.row]
        default:
            logger.error("error performing segue with identifier: \(segue.identifier ?? "nil")")
        }
    }
}

// MARK: - Dynamic Scene added delegate
extension DynamicScenesViewController: DynamicSceneAddDelegate {
    func dynamicSceneEdited(_ sender: DynamicScenesAddViewController, _ scene: RGBDynamicScene) {
        // Get the old realm object from row selected
        guard let indexPath = tableView.indexPathForSelectedRow else {
            // TODO: DISPLAY ERROR MESSAGE TO USER
            logger.error("Error receiving indexpath for selected row")
            return
        }
        guard let oldScene = realm.object(ofType: RGBDynamicScene.self,
                                          forPrimaryKey: dynamicScenes[1][indexPath.row].name) else {
            // TODO: DISPLAY ERROR MESSAGE TO USER
            logger.error("Error receiving object at selected row from Realm")
            return
        }
        // If the name is the same of another scene except the edited scene display error
        if dynamicScenes[1].contains(where: { $0.name == scene.name }) &&
            oldScene.name != scene.name {
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
        } else { // If the user edited the name or not, delete old scene and create a new scene in DB
            RGBDatabaseManager.write(to: realm, closure: { // Deleting old scene
                realm.delete(oldScene.xys)
                realm.delete(oldScene)
            })
            dynamicScenes[1][indexPath.row] = scene // Setting edited scene on tableview to new scene
            RGBDatabaseManager.write(to: realm, closure: { // Adding new scene to DB
                realm.add(scene, update: .all)
            })
            // Dismiss modal and reload changed row
            sender.dismiss(animated: true, completion: nil)
            tableView.reloadRows(at: [IndexPath(row: indexPath.row, section: 1)], with: .automatic)
        }
    }

    func dynamicSceneAdded(_ sender: DynamicScenesAddViewController, _ scene: RGBDynamicScene) {
        // If the name is the same as another scene display error
        if dynamicScenes[1].contains(where: { $0.name == scene.name }) ||
            dynamicScenes[0].contains(where: { $0.name == scene.name }) {
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
        } else { // Add to DB and insert row
            sender.dismiss(animated: true, completion: nil)
            dynamicScenes[1].append(scene)
            RGBDatabaseManager.write(to: realm, closure: {
                realm.add(scene, update: .all)
            })
            tableView.beginUpdates()
            tableView.insertRows(at: [IndexPath(row: dynamicScenes[1].count - 1, section: 1)], with: .automatic)
            if dynamicScenes[1].count == 1 {
                tableView.reloadSections(IndexSet(arrayLiteral: 1), with: .automatic)
            }
            tableView.endUpdates()
        }
    }

    func dynamicSceneDeleted(_ sender: DynamicScenesAddViewController) {
        sender.dismiss(animated: true, completion: nil)
        guard let indexPath = tableView.indexPathForSelectedRow else {
            // TODO: DISPLAY ERROR MESSAGE TO USER
            logger.error("Error receiving indexpath for selected row")
            return
        }
        RGBDatabaseManager.write(to: realm, closure: {
            realm.delete(dynamicScenes[1][indexPath.row].xys)
            realm.delete(dynamicScenes[1][indexPath.row])
        })
        dynamicScenes[1].remove(at: indexPath.row)
        tableView.beginUpdates()
        tableView.deleteRows(at: [IndexPath(row: indexPath.row, section: 1)], with: .automatic)
        if dynamicScenes[1].isEmpty {
            tableView.reloadSections(IndexSet(arrayLiteral: 1), with: .automatic)
        }
        tableView.endUpdates()
    }
}
