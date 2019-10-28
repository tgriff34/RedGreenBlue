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

    var swiftyHue: SwiftyHue = RGBRequest.shared.getSwiftyHue()
    var groups = [RGBGroup]()
    var dynamicScenes: [[RGBDynamicScene]] = []
    var navigationItems = [String]()

    var selectedGroupIndex = 0
    var shouldFetchDefault: Bool = true
    var selectedRowIndex: IndexPath?

    let realm = RGBDatabaseManager.realm()!

    let resultSearchController = UISearchController(searchResultsController: nil)
    var searchedScenes: [RGBDynamicScene] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // Setup search controller
        resultSearchController.searchResultsUpdater = self
        resultSearchController.obscuresBackgroundDuringPresentation = false
        resultSearchController.searchBar.placeholder = "Search dynamic scenes"
        resultSearchController.searchBar.scopeButtonTitles = RGBDynamicScene.Category.allCases.map { $0.stringValue }
        resultSearchController.searchBar.delegate = self
        navigationItem.searchController = resultSearchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true

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
    func fetchData() {
        guard let results = RGBDatabaseManager.realm()?.objects(RGBDynamicScene.self).filter("category = 1") else {
            logger.error("could not retrieve results of RGBDynamicScenes from DB")
            return
        }
        dynamicScenes.append(Array(results))

        if let userResults = RGBDatabaseManager.realm()?
            .objects(RGBDynamicScene.self)
            .filter("category = 2")
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
                self.selectedGroupIndex = self.navigationItems.firstIndex(of: defaultGroup)!
            } else if self.shouldFetchDefault {
                self.selectedGroupIndex = 0
            }
            self.shouldFetchDefault = false

            let menuView = BTNavigationDropdownMenu(title: BTTitle.index(self.selectedGroupIndex),
                                                    items: self.navigationItems)

            self.navigationItem.titleView = menuView

            menuView.cellBackgroundColor = self.view.backgroundColor
            menuView.checkMarkImage = UIImage(named: "checkmark")
            if #available(iOS 13, *) {
                menuView.menuTitleColor = UIColor.label
                menuView.arrowTintColor = UIColor.label
                menuView.cellTextLabelColor = UIColor.label
                menuView.cellSeparatorColor = UIColor.label
            } else {
                menuView.menuTitleColor = .black
                menuView.arrowTintColor = .black
                menuView.cellTextLabelColor = .black
            }
            menuView.didSelectItemAtIndexHandler = { (indexPath: Int) -> Void in
                self.selectedGroupIndex = indexPath
                if let selectedRowIndex = self.selectedRowIndex,
                    let cell = self.tableView.cellForRow(at: selectedRowIndex) as? LightsDynamicSceneCustomCell,
                    cell.switch.isOn {
                    RGBGroupsAndLightsHelper.shared.stopDynamicScene()
                    cell.switch.setOn(false, animated: true)
                    self.selectedRowIndex = nil
                }
            }
        })
    }

    private func isSearching() -> Bool {
        let searchBarScopeIsFiltering = resultSearchController.searchBar.selectedScopeButtonIndex != 0
        return resultSearchController.isActive && (!resultSearchController.searchBar.text!.isEmpty ||
            searchBarScopeIsFiltering)
    }
}

// MARK: - TableView
extension DynamicScenesViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        if isSearching() {
            return 1
        }
        return 2
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if isSearching() && section == 0 && searchedScenes.count > 0 {
            return "Search results"
        } else if !isSearching() && section == 0 {
            return "Default dynamic scenes"
        } else if !isSearching() && section == 1 && dynamicScenes[1].count > 0 {
            return "Your dynamic scenes"
        }
        return nil
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isSearching() {
            return searchedScenes.count
        }
        return dynamicScenes[section].count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DynamicScenesCellIdentifier")
            as! LightsDynamicSceneCustomCell // swiftlint:disable:this force_cast
        if isSearching() {
            cell.dynamicScene = searchedScenes[indexPath.row]
            cell.delegate = self
        } else {
            cell.dynamicScene = dynamicScenes[indexPath.section][indexPath.row]
            cell.delegate = self
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if indexPath.section == 0 || isSearching() {
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
        let genericErrorAdding = RGBSwiftMessages.createAlertInView(type: .error,
                                                                    fromNib: .cardView,
                                                                    content: ("Error editing scene", ""))
        let genericConfig = RGBSwiftMessages.createMessageConfig(windowLevel: .alert)
        guard let indexPath = tableView.indexPathForSelectedRow else {
            SwiftMessages.show(config: genericConfig, view: genericErrorAdding)
            logger.error("Error receiving indexpath for selected row")
            return
        }
        guard let oldScene = realm.object(ofType: RGBDynamicScene.self,
                                          forPrimaryKey: dynamicScenes[1][indexPath.row].name) else {
            SwiftMessages.show(config: genericConfig, view: genericErrorAdding)
            logger.error("Error receiving object at selected row from Realm")
            return
        }
        // If the name is the same of another scene except the edited scene display error
        if dynamicScenes[1].contains(where: { $0.name == scene.name }) && oldScene.name != scene.name {
            let sameNameErrorMessage = RGBSwiftMessages
                .createAlertInView(type: .warning, fromNib: .cardView,
                                   content: ("", "A scene by that name already exists"))
            let sameNameErrorConfig = RGBSwiftMessages.createMessageConfig(windowLevel: .alert)
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
            let sameNameErrorMessage = RGBSwiftMessages
                .createAlertInView(type: .warning, fromNib: .cardView,
                                   content: ("", "A scene by that name already exists"))
            let sameNameErrorConfig = RGBSwiftMessages.createMessageConfig(windowLevel: .alert)
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
            let genericErrorAdding = RGBSwiftMessages.createAlertInView(type: .error,
                                                                        fromNib: .cardView,
                                                                        content: ("Error deleting scene", ""))
            let genericConfig = RGBSwiftMessages.createMessageConfig()
            SwiftMessages.show(config: genericConfig, view: genericErrorAdding)
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

// MARK: - Search delegate
extension DynamicScenesViewController: UISearchResultsUpdating, UISearchBarDelegate {
    func filterContentForSearchText(_ searchText: String, category: RGBDynamicScene.Category? = nil) {
        if category == .all || category == .default {
            searchedScenes += dynamicScenes[0].filter { (dynamicScene: RGBDynamicScene) -> Bool in
                if searchText == "" { return true } else {
                    return dynamicScene.name.lowercased().contains(searchText.lowercased())
                }
            }
        }
        if category == .all || category == .custom {
            searchedScenes += dynamicScenes[1].filter { (dynamicScene: RGBDynamicScene) -> Bool in
                if searchText == "" { return true } else {
                    return dynamicScene.name.lowercased().contains(searchText.lowercased())
                }
            }
        }
        tableView.reloadData()
        if let indexPath = selectedRowIndex,
            let row = searchedScenes.firstIndex(of: dynamicScenes[indexPath.section][indexPath.row]) {
            tableView.selectRow(at: IndexPath(row: row, section: 0),
                                animated: true, scrollPosition: .none)
        }
    }

    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        guard let searchBarText = searchBar.text else { return }
        let category = RGBDynamicScene.Category(rawValue: selectedScope)
        filterContentForSearchText(searchBarText, category: category)
    }

    func updateSearchResults(for searchController: UISearchController) {
        self.searchedScenes = []
        if isSearching() {
            guard let searchBarText = searchController.searchBar.text else { return }
            let category = RGBDynamicScene.Category(rawValue: searchController.searchBar.selectedScopeButtonIndex)
            filterContentForSearchText(searchBarText, category: category)
        } else {
            tableView.reloadData()
            if let playingScene = RGBGroupsAndLightsHelper.shared.getPlayingScene() {
                if let row = dynamicScenes[0].firstIndex(of: playingScene) {
                    tableView.selectRow(at: IndexPath(row: row, section: 0),
                                        animated: true, scrollPosition: .none)
                } else if let row = dynamicScenes[1].firstIndex(of: playingScene) {
                    tableView.selectRow(at: IndexPath(row: row, section: 1),
                                        animated: true, scrollPosition: .none)
                }
            }
        }
    }
}
