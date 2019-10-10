//
//  TabBarViewController.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 10/9/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import UIKit

class TabBarViewController: UITabBarController {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let viewControllers = self.viewControllers!

        for (index, viewController) in viewControllers.enumerated() {
            if let viewController = viewController as? UINavigationController {
                switch index {
                case 1:
                    let scenesViewController = viewController.viewControllers.first! as? ScenesTableViewController
                    scenesViewController?.fetchData()
                case 2:
                    let dynamicViewController = viewController.viewControllers.first! as? DynamicScenesViewController
                    dynamicViewController?.fetchData()
                default:
                    break
                }
            }
        }
    }
}
