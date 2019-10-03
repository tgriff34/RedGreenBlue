//
//  AppDelegate.swift
//  RedGreenBlue
//
//  Created by Dana Griffin on 8/15/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import UIKit
import BackgroundTasks
import SwiftyBeaver

let logger = SwiftyBeaver.self
let console = SwiftyBeaver.self

fileprivate let backgroundTaskIdentifier = "com.RedGreenBlue.task.refresh"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions
        launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        let logFile = FileDestination()
        let consoleLog = ConsoleDestination()
        print("LOG FILE CAN BE FOUND AT: ", logFile.logFileURL ?? "")
        logger.addDestination(logFile)
        console.addDestination(consoleLog)

        self.window = UIWindow(frame: UIScreen.main.bounds)

        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let onboardingStoryboard = UIStoryboard(name: "Onboarding", bundle: nil)

        var viewControllerToPresent: UIViewController

        if UserDefaults.standard.bool(forKey: "isOnboard") {
            viewControllerToPresent = mainStoryboard.instantiateInitialViewController()!
        } else {
            viewControllerToPresent = onboardingStoryboard.instantiateInitialViewController()!
        }

        self.window?.rootViewController = viewControllerToPresent
        self.window?.makeKeyAndVisible()

        if #available(iOS 13.0, *) {
            BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundTaskIdentifier, using: nil, launchHandler: { task in
                //swiftlint:disable:next force_cast
                self.handleAppRefresh(task: task as! BGAppRefreshTask)
            })
        }

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        /* Sent when the application is about to move from active to inactive state.
           This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS
           message) or when the user quits the application and it begins the transition to the background state.
        
           Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks.
           Games should use this method to pause the game.
        */
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        /* Use this method to release shared resources, save user data, invalidate timers, and store enough
           application state information to restore your application to its current state in case it is terminated
           later.
           If your application supports background execution, this method is called instead of
           applicationWillTerminate: when the user quits.
        */
        if #available(iOS 13.0, *) {
            scheduleAppRefresh()
        } else {
        }
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of
        // the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive.
        // If the application was previously in the background, optionally refresh the user interface.
        RGBRequest.shared.setUpConnectionListeners()
        RGBRequest.shared.setApplicationTheme()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate.
        // See also applicationDidEnterBackground:.
    }
    
    @available(iOS 13.0, *)
    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: backgroundTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 1 * 60)
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            console.debug("Couldn't schedule app refresh: \(error)")
        }
    }
    
    @available(iOS 13.0, *)
    func handleAppRefresh(task: BGAppRefreshTask) {
        scheduleAppRefresh()
        
        console.debug("HELLO")
        task.setTaskCompleted(success: true)
    }
}
