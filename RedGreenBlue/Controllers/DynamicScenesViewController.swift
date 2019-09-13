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
    var timers = [Timer]()

    var selectedGroupIndex = 0

    @IBOutlet weak var tableView: UITableView!

    weak var delegate: MiniPlayerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        swiftyHue = RGBRequest.shared.getSwiftyHue()
        tableView.delegate = self
        tableView.dataSource = self
        fetchData()
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
    }

    func fetchData() {
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
            for group in groups {
                self.navigationItems.append(group.name)
            }
            self.setupDropdownNavigationBar()
        })
    }

    func setupDropdownNavigationBar() {
        let menuView = BTNavigationDropdownMenu(title: BTTitle.index(0), items: navigationItems)
        self.navigationItem.titleView = menuView
        self.tableView.reloadData()

        menuView.menuTitleColor = .white
        menuView.cellBackgroundColor = view.backgroundColor
        menuView.cellTextLabelColor = .white
        menuView.didSelectItemAtIndexHandler = { (indexPath: Int) -> Void in
            self.selectedGroupIndex = indexPath
        }
    }
}

extension DynamicScenesViewController {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dynamicScenes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // swiftlint:disable:next force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: "DynamicScenesCellIdentifier") as! LightSceneCustomCell
        cell.label.text = dynamicScenes[indexPath.row].name
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.miniPlayer(play: dynamicScenes[indexPath.row], for: groups[selectedGroupIndex])
    }
}

extension DynamicScenesViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? MiniPlayerViewController {
            self.delegate = destination
        }
    }
}
