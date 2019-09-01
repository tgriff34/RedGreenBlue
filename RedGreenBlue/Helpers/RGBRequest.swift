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

class RGBRequest {
    static func getGroups(with swiftyHue: SwiftyHue, completion: @escaping ([String: Group]) -> Void) {
        let resourceAPI = swiftyHue.resourceAPI
        resourceAPI.fetchGroups({ (result) in
            switch result {
            case .success:
                guard let groups = result.value else {
                    return
                }
                completion(groups)
            case .failure:
                print("Error recieving groups from API")
            }
        })
    }
    static func getLights(with swiftyHue: SwiftyHue, completion: @escaping ([String: Light]) -> Void) {
        let resourceAPI = swiftyHue.resourceAPI
        resourceAPI.fetchLights({ (result) in
            guard let lights = result.value else {
                return
            }
            completion(lights)
        })
    }
    static func getScenes(with swiftyHue: SwiftyHue, completion: @escaping ([String: PartialScene]) -> Void) {
        let resourceAPI = swiftyHue.resourceAPI
        resourceAPI.fetchScenes({ (result) in
            guard let scenes = result.value else {
                return
            }
            completion(scenes)
        })
    }
    static func setBridgeConfiguration(for RGBHueBridge: RGBHueBridge, with swiftyHue: SwiftyHue) {
        let bridgeAccessConfig = BridgeAccessConfig(bridgeId: "BridgeId",
                                                    ipAddress: RGBHueBridge.ipAddress,
                                                    username: RGBHueBridge.username)
        swiftyHue.setBridgeAccessConfig(bridgeAccessConfig)
    }

    static func setUpConnectionListeners() {
        NotificationCenter
            .default
            .addObserver(self,
                         selector: #selector(onConnectionUpdate(_:)),
                         name: NSNotification
                            .Name(BridgeHeartbeatConnectionStatusNotification.localConnection.rawValue),
                         object: nil)
        NotificationCenter
            .default
            .addObserver(self,
                         selector: #selector(onNoConnectionUpdate(_:)),
                         name: NSNotification
                            .Name(BridgeHeartbeatConnectionStatusNotification.nolocalConnection.rawValue),
                         object: nil)
    }

    private static var isConnected: Bool = false
    @objc private static func onConnectionUpdate(_ notification: Notification) {
        if !isConnected {
            isConnected = true
            setConnected(isConnected)
        }
    }

    @objc private static func onNoConnectionUpdate(_ notification: Notification) {
        isConnected = false
        setConnected(isConnected)
    }

    private static func setConnected(_ connected: Bool) {
        if connected {
            SwiftMessages.hide()
            let connectedMessage = MessageView.viewFromNib(layout: .cardView)
            connectedMessage.configureTheme(.success)
            connectedMessage.configureContent(title: "Connected", body: "")
            connectedMessage.layoutMarginAdditions = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
            connectedMessage.button?.isHidden = true
            (connectedMessage.backgroundView as? CornerRoundingView)?.cornerRadius = 10
            SwiftMessages.show(view: connectedMessage)
        } else {
            let errorMessage = MessageView.viewFromNib(layout: .cardView)
            var errorMessageConfig = SwiftMessages.Config()
            errorMessageConfig.duration = .forever
            errorMessageConfig.interactiveHide = false
            errorMessage.configureTheme(.error)
            errorMessage.configureContent(title: "Not connected", body: "")
            errorMessage.layoutMarginAdditions = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
            errorMessage.button?.isHidden = true
            (errorMessage.backgroundView as? CornerRoundingView)?.cornerRadius = 10
            SwiftMessages.show(config: errorMessageConfig, view: errorMessage)
        }
    }
}
