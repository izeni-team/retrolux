//
//  AppDelegate.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 6/1/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import UIKit

class Person: NSObject, Serializable {
    required override init() {
        super.init()
    }
    
    var name: String? = ""
    var friend: Person?
    
    static let optionalProperties = ["friend"]
    
    override var description: String {
        if let f = friend {
            return "Person{name: \(name), friend: \(f)}"
        } else {
            return "Person{name: \(name)}"
        }
    }
}

class ModelBase: RetroluxModel {
    var string = "(default value)"
    var string_opt: String? = "(default value)"
    var failure_string: String = "(default value)"
    var int = 0
    var float = 0.0
    var number_opt: NSNumber?
    var list_anyobject: [AnyObject]? = []
    var strings_2d: [[AnyObject]] = []
    var date: NSDate?
    var dates: [NSDate] = []
    var date_dict: [String: NSDate] = [:]
    var date_dict_array: [String: [[String: NSDate]]] = [:]
    var craycray: [String: [String: [String: [Int]]]] = [:]
    var person: Person?
    var friends: [Person] = []
    
    var thing: AnyObject?
    var thing_number: Int? {
        get {
            return thing as? Int
        }
        set {
            thing = newValue
        }
    }
    var thing_string: String? {
        get {
            return thing as? String
        }
        set {
            thing = newValue
        }
    }
    
    override class var optionalProperties: [String] {
        return ["failure_string"]
    }
    
    override class var ignoredProperties: [String] {
        return []
    }
    
    override var description: String {
        return "Model {\n" +
            "  string: \(string)\n" +
            "  string_opt: \(string_opt)\n" +
            "  failure_string: \(failure_string)\n" +
            "  int: \(int)\n" +
            "  float: \(float)\n" +
            "  number_opt: \(number_opt)\n" +
            "  list_anyobject: \(list_anyobject)\n" +
            "  strings_2d: \(strings_2d)\n" +
            "  date: \(date)\n" +
            "  dates: \(dates)\n" +
            "  date_dict: \(date_dict)\n" +
            "  date_dict_array: \(date_dict_array)\n" +
            "  craycray: \(craycray)\n" +
            "  person: \(person)\n" +
            "  friends: \(friends)\n" +
            "  thing_number: \(thing_number)\n" +
            "  thing_string: \(thing_string)\n" +
        "}"
    }
}

class Model: ModelBase {
    var notSerializable: Bool? = nil
    var inherited: Bool = false
    
    override class var ignoredProperties: [String] {
        return ["notSerializable"]
    }
    
    override var description: String {
        return super.description + "inherited: \(inherited)"
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        do {
            let dictionary = [
                "string": "Hello!",
                "string_opt": NSNull(),
                "failure_string": "",
                "int": 23,
                "float": 23.32,
                "thing": 2,
                "number_opt": NSNull(),
                "list_anyobject": [23, ["SURPRISE!"], NSNull()],
                "strings_2d": [["A", "B"], [2, "D"]],
                "date": "2015-04-23T12:03:00Z",
                "dates": ["2015-04-23T12:03:00Z", "2015-04-23T12:03:00Z"],
                "date_dict": ["test": "2015-04-23T12:03:00Z", "test2": "2015-04-23T12:03:00Z"],
                "date_dict_array": ["test": [["date": "2015-04-23T12:03:00Z"]]],
                "craycray": ["stuff": ["more_stuff": ["even_more_stuff": [1, 2, 3]]]],
                "person": [
                    "name": "Bob",
                    "whatever": true
                ],
                "friends": [
                    ["name": NSNull()],
                    ["name": "Jerry", "friend": ["name": "Ima Friend"]]
                ],
                "inherited": true
            ]
            print(String(data: try! NSJSONSerialization.dataWithJSONObject(dictionary, options: []), encoding: NSUTF8StringEncoding)!)
            let t = try Model(dictionary: dictionary)
            let serialized = try t.toJSONString()
            print("deserialized:", t)
            print("serialized:", serialized)
        } catch RetroluxException.SerializerError(let message) {
            print("exception:", message)
        } catch {
            print("Unknown exception")
        }

        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

