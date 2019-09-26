//
//  GroupProtocol.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 9/25/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import Foundation

protocol GroupAddDelegate: AnyObject {
    func groupAddedSuccess(_ name: String, _ lights: [String])
    func groupAddedCancelled()
}
