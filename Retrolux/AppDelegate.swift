//
//  AppDelegate.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 6/1/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import UIKit



@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        [String: AnyObject]().isEmpty
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
                ]
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

