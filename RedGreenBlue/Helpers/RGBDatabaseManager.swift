//
//  RGBDatabaseManager.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 8/24/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import RealmSwift

class RGBDatabaseManager {
    static func realm() -> Realm? {
        do {
            let realm = try Realm()
            return realm
        } catch {
            print("Could not access database: ", error)
        }
        return nil
    }

    static func write(to realm: Realm, closure: () -> Void) {
        do {
            try realm.write {
                closure()
            }
        } catch {
            print("Could not write to database: ", error)
        }
    }
}
