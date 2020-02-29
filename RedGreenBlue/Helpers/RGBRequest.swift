//
//  APIFetchRequest.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 8/16/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import Foundation
import UIKit
import SwiftyHue
import SwiftMessages
import CoreData

class RGBRequest {
    static let shared = RGBRequest()

    // Retrieves all groups and lights.  Creates a RGBGroup model which uses Group and Lights of that group.
    // Check RGBGroup model for more detail on what is contained in that model.
    func getGroups(with swiftyHue: SwiftyHue, completion: @escaping ([[RGBGroup]]?, Error?) -> Void) {
        let resourceAPI = swiftyHue.resourceAPI
        resourceAPI.fetchGroups({ (result) in
            switch result {
            case .success:
                guard let groups = result.value else { return }
                self.getLights(with: swiftyHue, completion: { (lights) in
                    var rgbGroups = [[RGBGroup]]()
                    var roomTypeGroups = [RGBGroup]()
                    var groupTypeGroups = [RGBGroup]()

                    let justGroups = Array(groups.values).map({ return $0 })
                    let justLights = Array(lights.values).map({ return $0 })

                    for group in justGroups {
                        var lightsInGroup = [Light]()
                        for light in justLights where group.lightIdentifiers!.contains(light.identifier) {
                            lightsInGroup.append(light)
                        }
                        lightsInGroup.sort(by: { $0.identifier < $1.identifier })
                        if group.type == .Room {
                            roomTypeGroups.append(RGBGroup(name: group.name, identifier: group.identifier,
                                                           lightIdentifiers: group.lightIdentifiers ?? [],
                                                           action: group.action, modelId: group.modelId ?? "",
                                                           type: group.type, lights: lightsInGroup))
                        } else {
                            groupTypeGroups.append(RGBGroup(name: group.name, identifier: group.identifier,
                                                            lightIdentifiers: group.lightIdentifiers ?? [],
                                                            action: group.action, modelId: group.modelId ?? "",
                                                            type: group.type, lights: lightsInGroup))
                        }
                    }
                    roomTypeGroups.sort(by: { $0.identifier.compare($1.identifier,
                                                                    options: .numeric) == .orderedAscending })
                    groupTypeGroups.sort(by: { $0.identifier.compare($1.identifier,
                                                                     options: .numeric) == .orderedAscending })

                    rgbGroups.append(roomTypeGroups)
                    rgbGroups.append(groupTypeGroups)
                    completion(rgbGroups, nil)
                })
            case .failure:
                completion(nil, ConnectionError.notConnected)
                logger.error("failure receiving data from API")
            }
        })
    }

    // Retrieves a single group by using the group id, this is used in LightsVC
    func getGroup(with identifier: String, using swiftyHue: SwiftyHue, completion: @escaping (RGBGroup) -> Void) {
        getGroups(with: swiftyHue, completion: { (groups, _) in
            for groupType in groups! {
                for group in groupType where group.identifier == identifier {
                    completion(group)
                }
            }
        })
    }

    // Retrieves all lights
    func getLights(with swiftyHue: SwiftyHue, completion: @escaping ([String: Light]) -> Void) {
        let resourceAPI = swiftyHue.resourceAPI
        resourceAPI.fetchLights({ (result) in
            switch result {
            case .success:
                guard let lights = result.value else {
                    return
                }
                completion(lights)
            case .failure:
                logger.error("Error recieving lights from API")
            }
        })
    }

    // Retrieves all scenes
    func getScenes(with swiftyHue: SwiftyHue, completion: @escaping ([String: PartialScene]?, Error?) -> Void) {
        let resourceAPI = swiftyHue.resourceAPI
        resourceAPI.fetchScenes({ (result) in
            switch result {
            case .success:
                guard let scenes = result.value else {
                    return
                }
                completion(scenes, nil)
            case .failure:
                completion(nil, ConnectionError.notConnected)
                logger.error("Error recieving scenes from API")
            }
        })
    }

    //============================================================================================================
    //============================================================================================================
    //============================================================================================================

    private var swiftyHue = SwiftyHue()
    private var rgbHueBridge: RGBHueBridge?
    private var ipAddress: String?

    func setSwiftyHue(ipAddress: String) -> SwiftyHue {
        UserDefaults.standard.set(ipAddress, forKey: "DefaultBridge")
        RGBGroupsAndLightsHelper.shared.stopDynamicScene()
        return getSwiftyHue()
    }

    func getSwiftyHue() -> SwiftyHue {
        _ = setCurrentlySelectedBridge(ipAddress: &ipAddress, rgbHueBridge: &rgbHueBridge, swiftyHue: &swiftyHue)

        return swiftyHue
    }

    // Sets current bridge selected.  If the ip in UserDefaults changed it will reconfigure settings to new bridge
    private func setCurrentlySelectedBridge(ipAddress: inout String?, rgbHueBridge: inout RGBHueBridge?,
                                            swiftyHue: inout SwiftyHue) -> Bool {
        if ipAddress != UserDefaults.standard.object(forKey: "DefaultBridge") as? String {
            ipAddress = UserDefaults.standard.object(forKey: "DefaultBridge") as? String

            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: RGBDatabaseManager.KEY_RGB_HUE_BRIDGE)
            fetchRequest.predicate = NSPredicate(format: "ipAddress == %@", ipAddress!)

            rgbHueBridge = RGBDatabaseManager.fetch(fetchRequest: fetchRequest)[0] as? RGBHueBridge

            setBridgeConfiguration(for: rgbHueBridge!, with: swiftyHue)

            return true
        }
        return false
    }

    // Sets bridge configuration for setCurrentlySelectedBridge
    private func setBridgeConfiguration(for RGBHueBridge: RGBHueBridge, with swiftyHue: SwiftyHue) {
        guard let ipAddress = RGBHueBridge.value(forKeyPath: "ipAddress") as? String,
            let username = RGBHueBridge.value(forKeyPath: "username") as? String else {
            return
        }

        let bridgeAccessConfig = BridgeAccessConfig(bridgeId: "BridgeId", ipAddress: ipAddress, username: username)

        swiftyHue.stopHeartbeat()
        swiftyHue.removeLocalHeartbeat(forResourceType: .lights)
        swiftyHue.setBridgeAccessConfig(bridgeAccessConfig)
        swiftyHue.setLocalHeartbeatInterval(3, forResourceType: .lights)
        swiftyHue.startHeartbeat()
    }

    // Sets connection observers so to know whether user is connected to the bridge or not
    private var isConnected: Bool = false
    func setUpConnectionListeners() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(onConnectionUpdate(_:)),
            name: NSNotification.Name(rawValue: BridgeHeartbeatConnectionStatusNotification.localConnection.rawValue),
            object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(onNoConnectionUpdate(_:)),
            name: NSNotification.Name(rawValue: BridgeHeartbeatConnectionStatusNotification.nolocalConnection.rawValue),
            object: nil)
    }

    func tearDownConnectionListeners() {
        isConnected = false
        NotificationCenter.default.removeObserver(
            self, name: NSNotification.Name(BridgeHeartbeatConnectionStatusNotification.localConnection.rawValue),
            object: nil)
        NotificationCenter.default.removeObserver(
            self, name: NSNotification.Name(BridgeHeartbeatConnectionStatusNotification.nolocalConnection.rawValue),
            object: nil)
    }

    // Connection observer helper functions
    @objc private func onConnectionUpdate(_ notification: Notification) {
        if !isConnected {
            isConnected = true
            setConnected(isConnected)
        }
    }

    @objc private func onNoConnectionUpdate(_ notification: Notification) {
        isConnected = false
        setConnected(isConnected)
    }

    private func setConnected(_ connected: Bool) {
        if connected {
            SwiftMessages.hideAll()
            let connectedMessage = RGBSwiftMessages
                .createAlertInView(type: .success, fromNib: .successCustomMessage, content: ("Connected", ""),
                                   layoutMarginAdditions: UIEdgeInsets(top: 5, left: 20, bottom: 10, right: 20))
            let connectedMessageConfig = RGBSwiftMessages.createMessageConfig(presentStyle: .bottom)
            SwiftMessages.show(config: connectedMessageConfig, view: connectedMessage)
        } else {
            let notConnectedMessage = RGBSwiftMessages
                .createAlertInView(type: .error, fromNib: .successCustomMessage, content: ("Not connected", ""),
                                   layoutMarginAdditions: UIEdgeInsets(top: 5, left: 20, bottom: 10, right: 20))
            let notConnectedMessageConfig = RGBSwiftMessages
                .createMessageConfig(presentStyle: .bottom, duration: .forever, interactiveHide: false)
            SwiftMessages.show(config: notConnectedMessageConfig, view: notConnectedMessage)
        }
    }

    func errorsFromResponse(error: Error?, completion: @escaping () -> Void) {
        RGBGroupsAndLightsHelper.shared.sendTimeSensistiveAPIRequest(withTimeInterval: 2, completion: {
            logger.error(String(describing: error?.localizedDescription))
            completion()
        })
    }

    // Sets the application theme to whatever key is in UserDefaults
    func setApplicationTheme() {
        if let window = UIApplication.shared.keyWindow {
            switch UserDefaults.standard.object(forKey: "AppTheme") as? String {
            case "dark":
                if #available(iOS 13.0, *) {
                    window.overrideUserInterfaceStyle = .dark
                }
            case "light":
                if #available(iOS 13.0, *) {
                    window.overrideUserInterfaceStyle = .light
                }
            case "system":
                if #available(iOS 13.0, *) {
                    window.overrideUserInterfaceStyle = UIScreen.main.traitCollection.userInterfaceStyle
                }
            default:
                logger.error("Error AppTheme is nil")
            }
        } else {
            let errorChangingTheme = RGBSwiftMessages
                .createAlertInView(type: .error, fromNib: .cardView,
                                   content: ("", "Error while attempting to change your theme"))
            let errorChangingThemeConfig = RGBSwiftMessages.createMessageConfig()
            SwiftMessages.show(config: errorChangingThemeConfig, view: errorChangingTheme)
        }
    }
}

enum ConnectionError: Error {
    case notConnected
}
