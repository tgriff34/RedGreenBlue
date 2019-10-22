//
//  DynamicSceneAddColorProtocol.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 9/24/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import Foundation
import RealmSwift

protocol DynamicSceneAddColorDelegate: AnyObject {
    func dynamicSceneColorAdded(_ color: XYColor)
}

protocol DynamicSceneAddAllColorsDelegate: AnyObject {
    func dynamicSceneColorsAdded(_ colors: List<XYColor>)
}

protocol DynamicSceneAddDelegate: AnyObject {
    func dynamicSceneAdded(_ sender: DynamicScenesAddViewController, _ scene: RGBDynamicScene)
    func dynamicSceneEdited(_ sender: DynamicScenesAddViewController, _ scene: RGBDynamicScene)
    func dynamicSceneDeleted(_ sender: DynamicScenesAddViewController)
}

protocol DynamicSceneColorOptionsDelegate: AnyObject {
    func lightsChangeColor(_ value: Bool)
    func timeBetweenCycle(_ time: Int)
    func lightsMultiColor(_ value: Bool)
    func lightsRandomColor(_ value: Bool)
    func lightsShiftRight(_ value: Bool)
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
