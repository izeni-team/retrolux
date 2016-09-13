//
//  Retrolux.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 6/4/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

//public enum RetroluxException: ErrorType {
//    case ReflectionError(ReflectionException)
//    case SerializerError(message: String)
//}

public struct ErrorResponse {
    
}

public enum Response<Body> {
    case success(body: Body)
    case failure(error: ErrorResponse)
}

public protocol SerializerProtocol {
    func deserialize(_ data: Data, output: Any.Type) throws -> Any
    func serialize(_ object: Any) throws -> Data
//    func supportsType(type: Any.Type) -> Bool // TODO: Implement this and pass in more info
}

open class Serializer: SerializerProtocol {
    open func deserialize(_ data: Data, output: Any.Type) throws -> Any {
        return try JSONSerialization.jsonObject(with: data, options: [])
    }
    
    open func serialize(_ object: Any) throws -> Data {
        // TODO: Force-casting Any to AnyObject is not safe.
        return try JSONSerialization.data(withJSONObject: object as AnyObject, options: [])
    }
    
//    public func supportsType(type: Any.Type) -> Bool {
//        return type == [String: AnyObject].self
//    }
}

func testbed() {
    //let r = Retrolux.sharedInstance
    //let newUser = User()
    //r.POST("/api/v1/users/", body: newUser, output: User.self)
}

open class Retrolux {
    open static let sharedInstance = Retrolux(baseURL: URL(string: "https://www.google.com/")!, serializer: Serializer(), httpClient: HTTPClient())
    
    open let baseURL: URL
    open let serializer: SerializerProtocol
    open let httpClient: HTTPClientProtocol
    open let headers: [String: String]
    
    public init(baseURL: URL, serializer: SerializerProtocol, httpClient: HTTPClientProtocol) {
        self.baseURL = baseURL
        self.serializer = serializer
        self.httpClient = httpClient
        self.headers = [:]
    }
}
