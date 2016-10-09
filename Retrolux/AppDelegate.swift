//
//  AppDelegate.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 6/1/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import UIKit

class Person: RLObject {
    var name: String? = "default"
    var isSelected: Bool? = false
    
    var friends: [String: Person] = [:]
    
    override var description: String {
        return "Person{name: \(name)}"
    }
    
    override class var ignoredProperties: [String] {
        return ["isSelected"]
    }
    
    override class var mappedProperties: [String : String] {
        return ["friendAges": "friend_ages"]
    }
}

class Diplomat: Person {
    var country: String?
    var another = ""
    
    override var description: String {
        return "Diplomat{name: \(name), country: \(country)}"
    }
    
    override class var ignoredProperties: [String] {
        return super.ignoredProperties + ["another"]
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        let person = Diplomat()
        
        class MyBuilder: Builder {
            var baseURL: URL
            var client: Client
            var callFactory: CallFactory
            var serializer: Serializer
            
            init(baseURL: URL, client: Client, callFactory: CallFactory, serializer: Serializer) {
                self.baseURL = baseURL
                self.client = client
                self.callFactory = callFactory
                self.serializer = serializer
            }
        }
        
        class LoginResponse: RLObject {
            var id = ""
            var token = ""
        }
        
        let requestBuilder = MyBuilder(baseURL: URL(string: "https://seek.izeni.net/")!, client: HTTPClient(), callFactory: HTTPCallFactory(), serializer: RLObjectJSONSerializer())
        
        class LoginBody: RLObject {
            var username = ""
            var password = ""
            
            convenience init(username: String, password: String) {
                self.init()
                self.username = username
                self.password = password
            }
        }
        
        class User: RLObject {
            var id = ""
            var first_name = ""
            var last_name = ""
            
            var name: String {
                return [first_name, last_name].flatMap { $0 }.joined(separator: " ")
            }
        }
        
        // Seek server problems:
        // - Password reset doesn't work using the app
        // - URL on admin should be USER_ID/password/, not USER_ID/change/password/
        
        let login = requestBuilder.makeRequest(
            method: .post,
            endpoint: "api-token-auth/",
            args: Body<LoginBody>(),
            response: Body<LoginResponse>()
        )
        
        let getUser = requestBuilder.makeRequest(
            method: .get,
            endpoint: "api/users/{id}/",
            args: Path("id"),
            response: Body<User>()
        )
        
        var token: String? {
            get {
                return UserDefaults.standard.value(forKey: "token") as? String
            }
            set {
                UserDefaults.standard.setValue(newValue, forKey: "token")
            }
        }
        
        var userID: String? {
            get {
                return UserDefaults.standard.value(forKey: "user_id") as? String
            }
            set {
                UserDefaults.standard.setValue(newValue, forKey: "user_id")
            }
        }
        
        requestBuilder.client.interceptor = { urlRequest in
            if let token = token {
                urlRequest.setValue("Token \(token)", forHTTPHeaderField: "Authorization")
            }
        }
        
        let afterLogin = { () -> Void in
            getUser(Path(userID!)).enqueue { response in
                switch response.result {
                case .success(let value):
                    print("User: \(value.name), \(value.id)")
                case .error(let error):
                    print("Get users error:", error)
                }
            }
        }
        
        if token == nil || userID == nil {
            let credentials = LoginBody(
                username: "bhenderson@izeni.com",
                password: "a45d8f47-0e93-42a5-9efe-2ce59001eb97"
            )
            
            login(Body(credentials)).enqueue { response in
                switch response.result {
                case .success(let value):
                    userID = value.id
                    token = value.token
                    afterLogin()
                case .error(let error):
                    print("Login error:", error)
                }
            }
        } else {
            afterLogin()
        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

