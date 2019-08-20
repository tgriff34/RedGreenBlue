//
//  APIFetchRequest.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 8/16/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import Foundation
import SwiftyHue

class RGBRequest {
    static func getGroups(with swiftyHue: SwiftyHue, completion: @escaping ([String: Group]) -> Void) {
        let resourceAPI = swiftyHue.resourceAPI
        resourceAPI.fetchGroups({ (result) in
            guard let groups = result.value else {
                return
            }
            completion(groups)
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
}
