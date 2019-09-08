//
//  GroupSliderProtocol.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 9/8/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import Foundation
import UIKit

protocol GroupSliderDelegate: AnyObject {
    func groupSlider(_ slider: UISlider, groupSliderStartedFor group: RGBGroup)
    func groupSlider(_ slider: UISlider, groupSliderMovedFor group: RGBGroup)
    func groupSlider(_ slider: UISlider, groupSliderEndedFor group: RGBGroup)
}
