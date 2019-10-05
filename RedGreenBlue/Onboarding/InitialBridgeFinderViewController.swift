//
//  InitialBridgeFinderViewController.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 8/27/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import UIKit
import SwiftyHue
import RealmSwift
import TORoundedButton
import NVActivityIndicatorView
import Canvas

class InitialBridgeFinderViewController: UIViewController {

    @IBOutlet weak var startButtonAnimationView: CSAnimationView!
    @IBOutlet weak var startApplicationButton: RoundedButton!
    @IBOutlet weak var labelAnimationView: CSAnimationView!
    @IBOutlet weak var label: UILabel!

    var bridgeFinder = BridgeFinder()
    var bridgeAuthenticators: [BridgeAuthenticator]?
    var foundBridges: [HueBridge]?

    var rgbBridge: RGBHueBridge?

    let realm: Realm? = RGBDatabaseManager.realm()

    var activityIndicatorView: NVActivityIndicatorView?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        bridgeFinder.delegate = self
        bridgeFinder.start()
        activityIndicatorView = NVActivityIndicatorView(frame: CGRect(x: self.view.frame.maxX / 2 - 50,
                                                                      y: self.view.frame.maxY / 2 - 50,
                                                                      width: 100, height: 100),
                                                        type: .ballPulse, color: UIColor.black, padding: 1)
        view.addSubview(activityIndicatorView!)
        activityIndicatorView?.startAnimating()
    }
}

extension InitialBridgeFinderViewController {
    func showStartButton() {
        startButtonAnimationView.type = CSAnimationTypeFadeIn
        startButtonAnimationView.duration = 1.0
        startButtonAnimationView.delay = 0
        startButtonAnimationView.startCanvasAnimation()
        self.startApplicationButton.isHidden = false
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "StartApplicationSegue":
            UserDefaults.standard.set(true, forKey: "isOnboard")
            UserDefaults.standard.set("Default", forKey: "DefaultCustomScene")
            UserDefaults.standard.set("Default", forKey: "DefaultScene")
            UserDefaults.standard.set("system", forKey: "AppTheme")
            UserDefaults.standard.set("Default", forKey: "SoundSetting")
            RGBDatabaseManager.write(to: realm!, closure: {
                let scene = RGBDynamicScene(name: "Christmas", timer: 10, brightnessDifference: 0,
                                            isDefault: true, sequentialLightChange: false,
                                            randomColors: true, soundFile: "Default")
                scene.xys.append(XYColor([Double(0.1356), Double(0.0412)]))
                scene.xys.append(XYColor([Double(0.6997), Double(0.3)]))
                scene.xys.append(XYColor([Double(0), Double(1)]))
                scene.xys.append(XYColor([Double(0.4944), Double(0.474)]))
                realm!.add(scene, update: .all)
            })
        default:
            logger.error("starting main application with segue: ", String(describing: segue.identifier))
        }
    }
}

extension InitialBridgeFinderViewController: BridgeAuthenticatorDelegate {
    func bridgeAuthenticator(_ authenticator: BridgeAuthenticator, didFinishAuthentication username: String) {
        guard let index = authenticator.tag else {
            let authString = String(describing: authenticator)
            let authStringTag = String(describing: authenticator.tag)
            logger.error("tag for authenticator not set: auth: \(authString)) index: \(authStringTag)")
            return
        }

        guard let bridge = foundBridges?[index] else {
            logger.error("could not find bridge in foundBridge: \(String(describing: foundBridges?[index]))")
            return
        }

        rgbBridge = RGBHueBridge(hueBridge: bridge)
        rgbBridge?.username = username

        if let realm = realm {
            RGBDatabaseManager.write(to: realm, closure: {
                realm.add(rgbBridge!, update: .modified)
            })
        }

        UserDefaults.standard.set(rgbBridge?.ipAddress, forKey: "DefaultBridge")

        activityIndicatorView?.stopAnimating()
        showStartButton()
    }

    func bridgeAuthenticator(_ authenticator: BridgeAuthenticator, didFailWithError error: NSError) {
        authenticator.start()
    }

    func bridgeAuthenticatorRequiresLinkButtonPress(_ authenticator: BridgeAuthenticator, secondsLeft: TimeInterval) {
    }

    func bridgeAuthenticatorDidTimeout(_ authenticator: BridgeAuthenticator) {
        authenticator.start()
    }
}

extension InitialBridgeFinderViewController: BridgeFinderDelegate {
    func bridgeFinder(_ finder: BridgeFinder, didFinishWithResult bridges: [HueBridge]) {
        //Animations
        self.label.text = "Press the button on the bridge you would like to connect to."

        activityIndicatorView?.stopAnimating()
        labelAnimationView.type = CSAnimationTypeFadeIn
        labelAnimationView.duration = 1.0
        labelAnimationView.delay = 0
        labelAnimationView.startCanvasAnimation()

        activityIndicatorView? = NVActivityIndicatorView(frame: CGRect(x: self.view.frame.maxX / 2 - 50,
                                                                       y: self.view.frame.maxY / 2 - 50,
                                                                       width: 100, height: 100),
                                                         type: .ballScaleMultiple, color: UIColor.black, padding: 1)
        self.view.addSubview(activityIndicatorView!)
        activityIndicatorView?.startAnimating()

        self.foundBridges = bridges
        for (index, bridge) in bridges.enumerated() {
            let bridgeAuthenticator = BridgeAuthenticator(bridge: bridge,
                                                         uniqueIdentifier: "swiftyhue#\(UIDevice.current.name)")
            bridgeAuthenticator.tag = index
            bridgeAuthenticator.delegate = self
            bridgeAuthenticator.start()
            bridgeAuthenticators?.append(bridgeAuthenticator)
        }
    }
}
