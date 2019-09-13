//
//  MiniPlayerProtocol.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 9/10/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import Foundation

protocol MiniPlayerDelegate: AnyObject {
    func miniPlayer(play scene: RGBDynamicScene, for group: RGBGroup)
}
