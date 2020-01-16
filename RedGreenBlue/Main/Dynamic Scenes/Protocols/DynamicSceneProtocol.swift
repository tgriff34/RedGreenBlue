//
//  DynamicSceneAddColorProtocol.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 9/24/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import Foundation
import UIKit

protocol DynamicSceneColorDelegate: AnyObject {
    func dynamicSceneColorAdded(_ color: UIColor)
    func dynamicSceneColorEdited(_ color: UIColor)
}

protocol DynamicSceneCustomColorDelegate: AnyObject {
    func dynamicSceneColorAdded(_ colors: [UIColor])
    func dynamicSceneColorEdited(_ color: UIColor)
}

protocol DynamicSceneAddAllColorsDelegate: AnyObject {
    func dynamicSceneColorsAdded(_ colors: [UIColor])
}

protocol DynamicSceneAddDelegate: AnyObject {
    func dynamicSceneAdded(_ sender: DynamicScenesAddViewController, _ newValues: [String: Any])
    func dynamicSceneEdited(_ sender: DynamicScenesAddViewController, _ updatedValues: [String: Any])
    func dynamicSceneDeleted(_ sender: DynamicScenesAddViewController)
}

protocol DynamicSceneColorOptionsDelegate: AnyObject {
    func lightsChangeColor(_ value: Bool)
    func timeBetweenCycle(_ type: TimeType, _ time: Int)
    func lightsMultiColor(_ value: Bool)
    func lightsRandomColor(_ value: Bool)
    func lightsShiftRight(_ value: Bool)
}

protocol DynamicSceneBrightnessOptionsDelegate: AnyObject {
    func minMaxBrightnessValues(_ min: Int, _ max: Int)
    func timeBetweenCycle(_ type: TimeType, _ time: Int)
    func fluctuatingBrightnessEnabled(_ value: Bool)
}

protocol DynamicSceneAddTimeDelegate: AnyObject {
    func dynamicSceneTimeAdded(_ type: TimeType, _ time: Int)
}

protocol DynamicSceneAddSoundFileDelegate: AnyObject {
    func dynamicSceneSoundFileAdded(_ name: String)
}

enum TimeType {
    case color
    case brightness
}
