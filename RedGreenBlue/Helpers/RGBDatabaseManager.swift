//
//  RGBDatabaseManager.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 8/24/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import RealmSwift
import CoreData
import SwiftyHue

class RGBDatabaseManager {
    /*
     TODO: Remove realm
     */
    static func realm() -> Realm? {
        do {
            let realm = try Realm()
            return realm
        } catch {
            logger.error("Could not access database: ", error.localizedDescription)
        }
        return nil
    }

    static func write(to realm: Realm, closure: () -> Void) {
        do {
            try realm.write {
                closure()
            }
        } catch {
            logger.error("Could not write to database: ", error.localizedDescription)
        }
    }

    //swiftlint:disable:next identifier_name
    static let KEY_RGB_HUEBRIDGE: String = "RGBHueBridge"

    //swiftlint:disable:next force_cast
    private static let appDelegate = UIApplication.shared.delegate as! AppDelegate
    private static let managedContext = appDelegate.persistentContainer.viewContext

    static func fetch(fetchRequest: NSFetchRequest<NSManagedObject>) -> [NSManagedObject] {
        do {
            return try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            logger.error("Could not fetch. \(error), \(error.userInfo)")
        }
        return []
    }

    static func addBridge(_ bridge: HueBridge, _ username: String, completion: @escaping (RGBHueBridge, NSError?) -> Void) {
        let entity = NSEntityDescription.entity(forEntityName: "RGBHueBridge", in: managedContext)!

        guard let newBridge = NSManagedObject(entity: entity, insertInto: managedContext) as? RGBHueBridge else {
            return
        }

        newBridge.setValue(bridge.deviceType, forKey: "deviceType")
        newBridge.setValue(bridge.friendlyName, forKey: "friendlyName")
        newBridge.setValue(bridge.ip, forKey: "ipAddress")
        newBridge.setValue(bridge.modelDescription, forKey: "modelDescription")
        newBridge.setValue(bridge.modelName, forKey: "modelName")
        newBridge.setValue(bridge.serialNumber, forKey: "serialNumber")
        newBridge.setValue(bridge.UDN, forKey: "udn")
        newBridge.setValue(username, forKey: "username")

        save(completion: { (error) in
            if let error = error {
                completion(newBridge, error)
                return
            }
            completion(newBridge, nil)
        })
    }

    static func delete(_ object: NSManagedObject) {
        managedContext.delete(object)
        save()
    }

    private static func save(completion: ((NSError?) -> Void)? = nil) {
        do {
            try managedContext.save()
            completion?(nil)
        } catch let error as NSError {
            logger.error("Could not save. \(error), \(error.userInfo)")
            completion?(error)
        }
    }
}
