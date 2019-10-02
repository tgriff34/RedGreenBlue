//
//  APIFetchRequest.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 8/16/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import Foundation
import SwiftyHue
import SwiftMessages
import RealmSwift

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

    func getSwiftyHue() -> SwiftyHue {
        _ = setCurrentlySelectedBridge(ipAddress: &ipAddress, rgbHueBridge: &rgbHueBridge, swiftyHue: &swiftyHue)

        return swiftyHue
    }

    func getSwiftyHueWithBool() -> (swiftyHue: SwiftyHue, didIpChange: Bool) {
        let didIpChange = setCurrentlySelectedBridge(ipAddress: &ipAddress, rgbHueBridge: &rgbHueBridge,
                                                     swiftyHue: &swiftyHue)

        return (swiftyHue, didIpChange)
    }

    // Sets current bridge selected.  If the ip in UserDefaults changed it will reconfigure settings to new bridge
    private func setCurrentlySelectedBridge(ipAddress: inout String?, rgbHueBridge: inout RGBHueBridge?,
                                            swiftyHue: inout SwiftyHue) -> Bool {
        if ipAddress != UserDefaults.standard.object(forKey: "DefaultBridge") as? String {
            ipAddress = UserDefaults.standard.object(forKey: "DefaultBridge") as? String
            rgbHueBridge = RGBDatabaseManager.realm()?.object(ofType: RGBHueBridge.self, forPrimaryKey: ipAddress)
            setBridgeConfiguration(for: rgbHueBridge!, with: swiftyHue)
            swiftyHue.setLocalHeartbeatInterval(3, forResourceType: .lights)
            return true
        }
        return false
    }

    // Sets bridge configuration for setCurrentlySelectedBridge
    private func setBridgeConfiguration(for RGBHueBridge: RGBHueBridge, with swiftyHue: SwiftyHue) {
        let bridgeAccessConfig = BridgeAccessConfig(bridgeId: "BridgeId",
                                                    ipAddress: RGBHueBridge.ipAddress,
                                                    username: RGBHueBridge.username)
        swiftyHue.setBridgeAccessConfig(bridgeAccessConfig)
    }

    // Sets connection observers so I know whether user is connected to the bridge or not
    private var isConnected: Bool = false
    func setUpConnectionListeners() {
        isConnected = false
        NotificationCenter.default.addObserver(self, selector: #selector(onConnectionUpdate(_:)),
                                               name: NSNotification.Name(rawValue:
                                                BridgeHeartbeatConnectionStatusNotification.localConnection.rawValue),
                                               object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onNoConnectionUpdate(_:)),
                                               name: NSNotification.Name(rawValue:
                                                BridgeHeartbeatConnectionStatusNotification.nolocalConnection.rawValue),
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
            SwiftMessages.hide()
            // swiftlint:disable:next force_try
            let connectedMessage: MessageView = try! SwiftMessages.viewFromNib(named: "SuccessCustomMessage")
            var connectedMessageConfig = SwiftMessages.Config()
            connectedMessageConfig.presentationContext = .window(windowLevel: .normal)
            connectedMessage.configureTheme(.success)
            connectedMessage.configureContent(title: "Connected", body: "")
            connectedMessage.layoutMarginAdditions = UIEdgeInsets(top: 5, left: 20, bottom: 10, right: 20)
            connectedMessage.button?.isHidden = true
            SwiftMessages.show(config: connectedMessageConfig, view: connectedMessage)
        } else {
            // swiftlint:disable:next force_try
            let errorMessage: MessageView = try! SwiftMessages.viewFromNib(named: "SuccessCustomMessage")
            var errorMessageConfig = SwiftMessages.Config()
            errorMessageConfig.presentationContext = .window(windowLevel: .normal)
            errorMessageConfig.duration = .forever
            errorMessageConfig.interactiveHide = false
            errorMessage.configureTheme(.error)
            errorMessage.configureContent(title: "Not connected", body: "")
            errorMessage.layoutMarginAdditions = UIEdgeInsets(top: 5, left: 20, bottom: 10, right: 20)
            errorMessage.button?.isHidden = true
            (errorMessage.backgroundView as? CornerRoundingView)?.cornerRadius = 10
            SwiftMessages.show(config: errorMessageConfig, view: errorMessage)
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
            let errorGettingUIWindow: MessageView = MessageView.viewFromNib(layout: .messageView)
            var errorGettingUIWindowConfig = SwiftMessages.Config()
            errorGettingUIWindowConfig.presentationContext = .window(windowLevel: .normal)
            errorGettingUIWindow.configureTheme(.warning)
            errorGettingUIWindow.configureContent(title: "Error Changing Theme",
                                                  body: "An error ocurred while changing your theme!")
            errorGettingUIWindow.layoutMarginAdditions = UIEdgeInsets(top: 5, left: 20, bottom: 10, right: 20)
            errorGettingUIWindow.button?.isHidden = true
            SwiftMessages.show(config: errorGettingUIWindowConfig, view: errorGettingUIWindow)
        }
    }
}

enum ConnectionError: Error {
    case notConnected
}
