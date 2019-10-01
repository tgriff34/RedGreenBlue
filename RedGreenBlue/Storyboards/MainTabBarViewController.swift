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
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForground(_:)),
                                               name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    @objc func applicationWillEnterForground(_ notification: NSNotification) {
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
                UIScreen.main.traitCollection.userInterfaceStyle
                switch UIScreen.main.traitCollection.userInterfaceStyle {
                case .dark:
                    console.debug("DARK")
                case .light:
                    console.debug("LIght")
                case .unspecified:
                    console.debug("Unspecified")
                }
                overrideUserInterfaceStyle = UIScreen.main.traitCollection.userInterfaceStyle
            }
        default:
            logger.error("Error AppTheme is nil")
        }
    }
}
