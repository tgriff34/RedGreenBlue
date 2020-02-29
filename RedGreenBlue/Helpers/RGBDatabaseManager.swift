//
//  RGBDatabaseManager.swift
//  RedGreenBlue
//
//  Created by Tristan Griffin on 8/24/19.
//  Copyright © 2019 Dana Griffin. All rights reserved.
//

import CoreData
import SwiftyHue

class RGBDatabaseManager {
    //swiftlint:disable:next identifier_name
    static let KEY_RGB_HUE_BRIDGE: String = "RGBHueBridge"
    //swiftlint:disable:next identifier_name
    static let KEY_RGB_DYNAMIC_SCENE: String = "RGBDynamicScene"

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

    static func addBridge(_ bridge: HueBridge, _ username: String,
                          completion: @escaping (RGBHueBridge, NSError?) -> Void) {
        let entity = NSEntityDescription.entity(forEntityName: KEY_RGB_HUE_BRIDGE, in: managedContext)!

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

    //swiftlint:disable:next function_parameter_count
    static func addScene(name: String, timer: Double, category: Category, displayMultipleColors: Bool,
                         isBrightnessEnabled: Bool, lightsChangeColor: Bool, randomColors: Bool,
                         sequentialLightChange: Bool, brightnessTimer: Double, maxBrightness: Int, minBrightness: Int,
                         soundFile: String, colors: [UIColor]) {
        let entity = NSEntityDescription.entity(forEntityName: KEY_RGB_DYNAMIC_SCENE, in: managedContext)!

        guard let newScene = NSManagedObject(entity: entity, insertInto: managedContext) as? RGBDynamicScene else {
            return
        }

        newScene.name = name
        newScene.category = category
        newScene.displayMultipleColors = displayMultipleColors
        newScene.isBrightnessEnabled = isBrightnessEnabled
        newScene.lightsChangeColor = lightsChangeColor
        newScene.maxBrightness = Int64(maxBrightness)
        newScene.minBrightness = Int64(minBrightness)
        newScene.brightnessTimer = brightnessTimer
        newScene.randomColors = randomColors
        newScene.sequentialLightChange = sequentialLightChange
        newScene.soundFile = soundFile
        newScene.timer = timer
        newScene.colors = colors

        save()
    }

    static func addScene(newValues: [String: Any], completion: @escaping (RGBDynamicScene, NSError?) -> Void) {
        let entity = NSEntityDescription.entity(forEntityName: KEY_RGB_DYNAMIC_SCENE, in: managedContext)!

        guard let newScene = NSManagedObject(entity: entity, insertInto: managedContext) as? RGBDynamicScene else {
            return
        }

        if let name = newValues["name"] as? String,
            let category = newValues["category"] as? Category,
            let displayMultipleColors = newValues["displayMultipleColors"] as? Bool,
            let isBrightnessEnabled = newValues["isBrightnessEnabled"] as? Bool,
            let lightsChangeColor = newValues["lightsChangeColor"] as? Bool,
            let maxBrightness = newValues["maxBrightness"] as? Int,
            let minBrightness = newValues["minBrightness"] as? Int,
            let brightnessTimer = newValues["brightnessTimer"] as? Double,
            let randomColors = newValues["randomColors"] as? Bool,
            let sequentialLightChange = newValues["sequentialLightChange"] as? Bool,
            let soundFile = newValues["soundFile"] as? String,
            let timer = newValues["timer"] as? Double,
            let colors = newValues["colors"] as? [UIColor] {

            newScene.name = name
            newScene.category = category
            newScene.displayMultipleColors = displayMultipleColors
            newScene.isBrightnessEnabled = isBrightnessEnabled
            newScene.lightsChangeColor = lightsChangeColor
            newScene.maxBrightness = Int64(maxBrightness)
            newScene.minBrightness = Int64(minBrightness)
            newScene.brightnessTimer = brightnessTimer
            newScene.randomColors = randomColors
            newScene.sequentialLightChange = sequentialLightChange
            newScene.soundFile = soundFile
            newScene.timer = timer
            newScene.colors = colors

            save(completion: { (error) in
                if let error = error {
                    completion(newScene, error)
                    return
                }
                completion(newScene, nil)
            })
        }
    }

    static func updateScene(scene: RGBDynamicScene, updatedValues: [String: Any],
                            completion: @escaping (RGBDynamicScene, NSError?) -> Void) {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: KEY_RGB_DYNAMIC_SCENE)
        fetchRequest.predicate = NSPredicate(format: "name == %@", scene.name)

        if let rgbds = fetch(fetchRequest: fetchRequest)[0] as? RGBDynamicScene,
            let name = updatedValues["name"] as? String,
            let category = updatedValues["category"] as? Category,
            let displayMultipleColors = updatedValues["displayMultipleColors"] as? Bool,
            let isBrightnessEnabled = updatedValues["isBrightnessEnabled"] as? Bool,
            let lightsChangeColor = updatedValues["lightsChangeColor"] as? Bool,
            let maxBrightness = updatedValues["maxBrightness"] as? Int,
            let minBrightness = updatedValues["minBrightness"] as? Int,
            let brightnessTimer = updatedValues["brightnessTimer"] as? Double,
            let randomColors = updatedValues["randomColors"] as? Bool,
            let sequentialLightChange = updatedValues["sequentialLightChange"] as? Bool,
            let soundFile = updatedValues["soundFile"] as? String,
            let timer = updatedValues["timer"] as? Double,
            let colors = updatedValues["colors"] as? [UIColor] {

            rgbds.name = name
            rgbds.category = category
            rgbds.displayMultipleColors = displayMultipleColors
            rgbds.isBrightnessEnabled = isBrightnessEnabled
            rgbds.lightsChangeColor = lightsChangeColor
            rgbds.maxBrightness = Int64(maxBrightness)
            rgbds.minBrightness = Int64(minBrightness)
            rgbds.brightnessTimer = brightnessTimer
            rgbds.randomColors = randomColors
            rgbds.sequentialLightChange = sequentialLightChange
            rgbds.soundFile = soundFile
            rgbds.timer = timer
            rgbds.colors = colors

            save(completion: { (error) in
                if let error = error {
                    completion(rgbds, error)
                    return
                }
                completion(rgbds, nil)
            })
        }
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
