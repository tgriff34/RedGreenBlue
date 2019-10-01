//
//  MainTabBarViewController.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 10/1/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import UIKit

class MainTabBarViewController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()

        switch UserDefaults.standard.object(forKey: "AppTheme") as? String {
        case "dark":
            if #available(iOS 13.0, *) {
                overrideUserInterfaceStyle = .dark
            }
        case "light":
            if #available(iOS 13.0, *) {
                overrideUserInterfaceStyle = .light
            }
        case "system":
            if #available(iOS 13.0, *) {
                overrideUserInterfaceStyle = UIScreen.main.traitCollection.userInterfaceStyle
            }
        default:
            logger.error("Error AppTheme is nil")
        }
    }
}
