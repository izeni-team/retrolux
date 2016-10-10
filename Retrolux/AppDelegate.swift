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

enum InterpretedResponse<T> {
    case success(value: T)
    case failure(error: InterpretedError)
}

struct InterpretedError {
    let message: String
    
    init(response: ClientResponse?, serializerError: Error?) {
        self.message = "TODO"
    }
    
    func presentError(on viewController: UIViewController, errorTitle: String) {
        let alert = UIAlertController(title: errorTitle, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        viewController.present(alert, animated: false, completion: nil)
    }
}

extension Response {
    var interpreted: InterpretedResponse<T> {
//        if let error = self.rawResponse.error {
            return .failure(error: InterpretedError(response: rawResponse, serializerError: result.error))
//        }
//
//
//        let status = rawResponse.status ?? 0
//        switch status {
//        case 200...299:
//            switch result {
//            case .success(let value):
//                return .success(value: value)
//            case .failure(let error):
//                return .failure(error: InterpretedError(response: response, serializerError: error))
//            }
//        case 300...399:
//            let userInfo = [NSLocalizedDescriptionKey: ""]
//            return .failure(error: ErrorResponse(error: NSError(domain: "retrolux", code: 300, userInfo: userInfo)))
//        case 400...499:
//            let userInfo = [NSLocalizedDescriptionKey: ""]
//            return .failure(error: ErrorResponse(error: NSError(domain: "retrolux", code: 400, userInfo: userInfo)))
//        case 500...599:
//            let userInfo = [NSLocalizedDescriptionKey: ""]
//            return .failure(error: ErrorResponse(error: NSError(domain: "retrolux", code: 500, userInfo: userInfo)))
//        default:
//            let userInfo = [NSLocalizedDescriptionKey: ""]
//            return .failure(error: ErrorResponse(error: NSError(domain: "retrolux", code: 1, userInfo: userInfo)))
//        }
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
        
        class NewUser: RLObject {
            var email = ""
            var password = ""
            
            convenience init(email: String, password: String) {
                self.init()
                self.email = email
                self.password = password
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
        
        let patchUser = requestBuilder.makeRequest(
            method: .patch,
            endpoint: "api/users/{id}/",
            args: (Path("id"), Body<User>()),
            response: Body<User>()
        )
        
        let createUser = requestBuilder.makeRequest(
            method: .post,
            endpoint: "api/users/",
            args: Body<NewUser>(),
            response: Body<User>()
        )
        
        let deleteUser = requestBuilder.makeRequest(
            method: .delete,
            endpoint: "api/users/{id}/",
            args: Path("id"),
            response: Body<Void>()
        )
        
        let getUsers = requestBuilder.makeRequest(
            method: .get,
            endpoint: "api/users/",
            args: (),
            response: Body<[User]>()
        )
        
        deleteUser(Path("asdf")).enqueue { response in
            print(response)
            switch response.interpreted {
            case .success(let value):
                print("Deleted user successfully.")
            case .failure(let error):
                print("Failed to delete user: \(error)")
            }
        }
        
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
        
        getUsers().enqueue { response in
            switch response.result {
            case .success(let values):
                print("Got users: \(values.count)")
            case .failure(let error):
                print("Failed to get list of users: \(error)")
            }
        }
        
        let create = false
        if create {
            let newUser = NewUser(
                email: "bhenderson+rl002@izeni.com",
                password: "a45d8f47-0e93-42a5-9efe-2ce59001eb97"
            )
            createUser(Body(newUser)).enqueue { createResponse in
                switch createResponse.result {
                case .success(let value):
                    print("New user created")
                    print(value.first_name, value.last_name, value.id)
                case .failure(let error):
                    print("Error creating new user: \(error)")
                }
            }
        }
        
        let afterLogin = { () -> Void in
            getUser(Path(userID!)).enqueue { response in
                switch response.result {
                case .success(let value):
                    print("User: \(value.name), \(value.id)")
                    
                    let modified = value
                    modified.first_name = "ALICE"
                    
                    patchUser((Path(value.id), Body(modified))).enqueue { patchResponse in
                        switch patchResponse.result {
                        case .success(let patchedUser):
                            print("Patched user was successful.")
                            print("User's name is now: \(patchedUser.first_name)")
                        case .failure(let error):
                            print("Error patching: \(error)")
                        }
                    }
                case .failure(let error):
                    print("Get users error:", error)
                }
            }
        }
        
        if token == nil || userID == nil {
            let credentials = LoginBody(
                username: "bhenderson+rl002@izeni.com",
                password: "a45d8f47-0e93-42a5-9efe-2ce59001eb97"
            )
            
            login(Body(credentials)).enqueue { response in
                switch response.result {
                case .success(let value):
                    userID = value.id
                    token = value.token
                    afterLogin()
                case .failure(let error):
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

