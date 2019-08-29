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

            guard let lightGroupsTableViewController = segue.destination as? LightGroupsTableViewController else {
                print("Error casting ", String(describing: segue.destination), " as LightGroupsTableViewController")
                return
            }

            lightGroupsTableViewController.rgbBridge = rgbBridge
        default:
            print("Error starting main application with segue: ", String(describing: segue.identifier))
        }
    }
}

extension InitialBridgeFinderViewController: BridgeAuthenticatorDelegate {
    func bridgeAuthenticator(_ authenticator: BridgeAuthenticator, didFinishAuthentication username: String) {
        guard let index = authenticator.tag else {
            print("Error tag for authenticator not set")
            return
        }

        guard let bridge = foundBridges?[index] else {
            print("Error could not find bridge in foundBridges")
            return
        }

        rgbBridge = RGBHueBridge(hueBridge: bridge)
        rgbBridge?.username = username

        if let realm = realm {
            RGBDatabaseManager.write(to: realm, closure: {
                realm.add(rgbBridge!)
            })
        }

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