//
//  LightCellProtocol.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 9/8/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import Foundation
import SwiftyHue

protocol LightsCellDelegate: AnyObject {
    func lightsTableViewCell(_ lightsTableViewCell: LightsCustomCell, lightSwitchTappedFor light: Light)
    func lightsTableViewCell(_ lightsTabelViewCell: LightsCustomCell, lightSliderStartedFor light: Light)
    func lightsTableViewCell(_ lightsTableViewCell: LightsCustomCell, lightSliderMovedFor light: Light)
    func lightsTableViewCell(_ lightsTableViewCell: LightsCustomCell, lightSliderEndedFor light: Light)
}
