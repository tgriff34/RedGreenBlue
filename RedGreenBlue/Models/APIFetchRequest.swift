//
//  APIFetchRequest.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 8/16/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import Foundation
import SwiftyHue

class APIFetchRequest {
    static func fetchLightGroups(swiftyHue: SwiftyHue, completion: @escaping ([String], [String: Group]) -> Void) {
        let resourceAPI = swiftyHue.resourceAPI
        resourceAPI.fetchGroups({ (result) in
            guard let groups = result.value else {
                return
            }
            var groupIdentifiers: [String] = []
            for group in groups {
                groupIdentifiers.append(group.key)
            }
            groupIdentifiers.sort()

            completion(groupIdentifiers, groups)
        })
    }

    static func fetchAllLights(swiftyHue: SwiftyHue, completion: @escaping ([String: Light]) -> Void) {
        let resourceAPI = swiftyHue.resourceAPI
        resourceAPI.fetchLights({ (result) in
            guard let groups = result.value else {
                return
            }
            completion(groups)
        })
    }
}
