//
//  RGBSwiftMessages.swift
//  RedGreenBlue
//
//  Created by Dana Griffin on 10/12/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//
//  Helper functions for creating SwiftyMessages alert views and configs
//
import Foundation
import SwiftMessages

public enum RGBMessageNibs {
    case infiniteSpinner
    case successCustomMessage
    case cardView
    case messageView
    case tabView
    case centeredView
    case statusLine
}

class RGBSwiftMessages {
    static func createAlertInView(type: Theme,
                                  fromNib: RGBMessageNibs,
                                  forever: Bool = false,
                                  infoSpinner: Bool = false,
                                  content: (String, String),
                                  layoutMarginAdditions: UIEdgeInsets? = nil,
                                  buttonShown: Bool = false,
                                  cornerRadius: CGFloat = CGFloat(10)) -> MessageView {

        var messageAlert: MessageView?

        switch fromNib {
        case .cardView:
            messageAlert = MessageView.viewFromNib(layout: .cardView)
        case .statusLine:
            messageAlert = MessageView.viewFromNib(layout: .statusLine)
        case .centeredView:
            messageAlert = MessageView.viewFromNib(layout: .centeredView)
        case .tabView:
            messageAlert = MessageView.viewFromNib(layout: .tabView)
        case .messageView:
            messageAlert = MessageView.viewFromNib(layout: .messageView)
        case .infiniteSpinner:
            // swiftlint:disable:next force_try
            messageAlert = try! SwiftMessages.viewFromNib(named: "CustomMessageView")
        case .successCustomMessage:
            // swiftlint:disable:next force_try
            messageAlert = try! SwiftMessages.viewFromNib(named: "SuccessCustomMessage")
        }

        switch type {
        case .info:
            messageAlert?
                .configureTheme(backgroundColor: UIColor(displayP3Red: 0.0, green: 122.0/255.0, blue: 1.0, alpha: 1.0),
                                foregroundColor: .white, iconImage: Icon.info.image)
        default:
            messageAlert?.configureTheme(type)
        }

        messageAlert?.configureDropShadow()
        messageAlert?.configureContent(title: content.0, body: content.1)
        messageAlert?.button?.isHidden = !buttonShown
        (messageAlert?.backgroundView as? CornerRoundingView)?.cornerRadius = cornerRadius

        if layoutMarginAdditions != nil {
            messageAlert?.layoutMarginAdditions = layoutMarginAdditions!
        } else {
            messageAlert?.layoutMarginAdditions = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        }

        return messageAlert!
    }

    static func createMessageConfig(presentStyle: SwiftMessages.PresentationStyle = .top,
                                    duration: SwiftMessages.Duration = .automatic, dim: Bool = false,
                                    dimInteractive: Bool = false, interactiveHide: Bool = true,
                                    windowLevel: UIWindow.Level = .alert) -> SwiftMessages.Config {

        var messageConfig = SwiftMessages.Config()

        messageConfig.duration = duration
        if dim == true {
            messageConfig.dimMode = .gray(interactive: false)
        } else if dimInteractive == true {
            messageConfig.dimMode = .gray(interactive: true)
        }
        messageConfig.presentationContext = .window(windowLevel: windowLevel)
        messageConfig.presentationStyle = presentStyle
        messageConfig.interactiveHide = interactiveHide

        return messageConfig
    }
}
