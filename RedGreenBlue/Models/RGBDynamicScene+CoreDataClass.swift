//
//  RGBDynamicScene+CoreDataClass.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 1/13/20.
//  Copyright © 2020 Dana Griffin. All rights reserved.
//
//

import Foundation
import CoreData

enum Category: Int32, CaseIterable {
    //swiftlint:disable:next identifier_name
    case All, `Default`, Custom
}

@objc(RGBDynamicScene)
public class RGBDynamicScene: NSManagedObject {
    var category: Category {
        get {
            return Category(rawValue: self.categoryValue)!
        }
        set {
            self.categoryValue = newValue.rawValue
        }
    }
}
