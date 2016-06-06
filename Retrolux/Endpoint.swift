//
//  Endpoint.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 6/5/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

//class User: RetroluxObject {
//    
//}
//
//struct API {
//    static let root = Endpoint(URL: NSURL(string: "https://api.amiigo.com/api/v1/")).addHeaders(["Content-Type": "application/json"])
//    
//    struct QueryParams {
//        let id: String
//    }
//    
//    static let users = root.extend("users/")
//    static let searchUsers = users.GET(User.self)
//    static let searchUsers = GET("users/", response: User.self)
//    static let searchUsers = endpoint(.GET, path: "users/", response: User.self)
//    static let searchUsers = endpoint(.POST, path: "users/", body: User.self, response: User.self)
//    
//    static func getUser(id id: String, callback: (response: ObjectResponse<User>) -> Void) {
//        users.extend(id + "/").GET(User.self)(callback: callback)
//    }
//    
//    static let
////    static func getUser(id: String, callback: (response: Response<User>) -> Void) {
////        usersEndpoint.extend("\(id)/").GET(User.self)(callback)
////    }
////    static let getUser = usersEndpoint.extend("{id}/").GET(User.self)
////    static let getUsers = usersEndpoint.GET(Array<User>.self)
//}
//
//func testStuff() {
////    API.usersEndpoint()
//    API.searchUsers.params(["first_name": "Bryan"]).response({ response in
//        
//    })
//}
//
//public struct Endpoint {
//    private(set) public var URL: NSURL
//    private(set) public var headers: [String: String]
//    private(set) public var tags: Set<String>
//    private var httpMethod: HTTPMethod?
//    
//    public init(URL: NSURL!, headers: [String: String] = [:], tags: Set<String> = Set()) {
//        self.URL = URL
//        self.headers = headers
//        self.tags = tags
//    }
//    
//    public func extend(component: String) -> Endpoint {
//        var copy = self
//        copy.URL = URL.URLByAppendingPathComponent(component)
//        return copy
//    }
//    
//    public func addHeaders(input: [String: String]) -> Endpoint {
//        var copy = self
//        for (key, value) in input {
//            copy.headers[key] = value
//        }
//        return copy
//    }
//    
//    public func tag(tag: String) -> Endpoint {
//        var copy = self
//        copy.tags.insert(tag)
//        return copy
//    }
//
//    public func method(method: HTTPMethod) -> FinalizedEndpoint {
//        var copy = self
//        copy.httpMethod = method
//        return FinalizedEndpoint(endpoint: copy)
//    }
//}
//
//public struct FinalizedEndpoint {
//    private let endpoint: Endpoint
//    
//    func noSerialization() -> () -> Void {
//        return {}
//    }
//    func serialize<Input: Serializable>(input input: Input.Type) -> () -> Void {
//        return {}
//    }
//    func serialize<Input: Serializable>(input input: Array<Input>.Type) -> () -> Void {
//        return {}
//    }
//    func serialize<Output: Serializable>(output output: Output.Type) -> () -> Void {
//        return {}
//    }
//    func serialize<Output: Serializable>(output output: Array<Output>.Type) -> () -> Void {
//        return {}
//    }
//    
//    func serialize<Input: Serializable, Output: Serializable>(input input: Input.Type, output: Output.Type? = nil) -> () -> Void {
//        print(input, output)
//        return {}
//    }
//    func serialize<Input: Serializable, Output: Serializable>(input input: Array<Input>.Type, output: Output.Type) -> () -> Void {
//        return {}
//    }
//    func serialize<Input: Serializable, Output: Serializable>(input input: Input.Type, output: Array<Output>.Type) -> () -> Void {
//        return {}
//    }
//    func serialize<Input: Serializable, Output: Serializable>(input input: Array<Input>.Type, output: Array<Output>.Type) -> () -> Void {
//        return {}
//    }
//}
//
//extension Endpoint {
//    func GET<Output: Serializable>(output: Output.Type) -> () -> Void {
//        return method(.GET).serialize(output: output)
//    }
//    func GET<Output: Serializable>(output: Array<Output>.Type) -> () -> Void {
//        return method(.GET).serialize(output: output)
//    }
//    
//    func POST<Input: Serializable, Output: Serializable>(input: Input.Type, output: Output.Type) -> () -> Void {
//        return method(.POST).serialize(input: input, output: output)
//    }
//    
//    func POST<T: Serializable>(inputAndOutput: T.Type) -> () -> Void {
//        return method(.POST).serialize(input: inputAndOutput, output: inputAndOutput)
//    }
//}