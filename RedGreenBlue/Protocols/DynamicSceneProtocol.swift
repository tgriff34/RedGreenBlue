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
}

protocol DynamicSceneAddTimeDelegate: AnyObject {
    func dynamicSceneTimeAdded(_ time: Int)
}
