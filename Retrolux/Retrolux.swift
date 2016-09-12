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
    case Success(body: Body)
    case Failure(error: ErrorResponse)
}

public protocol SerializerProtocol {
    func deserializeData(data: NSData, output: Any.Type) throws -> Any
    func serializeToData(object: Any) throws -> NSData
//    func supportsType(type: Any.Type) -> Bool // TODO: Implement this and pass in more info
}

public class Serializer: SerializerProtocol {
    public func deserializeData(data: NSData, output: Any.Type) throws -> Any {
        return try NSJSONSerialization.JSONObjectWithData(data, options: [])
    }
    
    public func serializeToData(object: Any) throws -> NSData {
        // TODO: Force-casting Any to AnyObject is not safe.
        return try NSJSONSerialization.dataWithJSONObject(object as! AnyObject, options: [])
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

public class Retrolux {
    public static let sharedInstance = Retrolux(baseURL: NSURL(string: "https://www.google.com/")!, serializer: Serializer(), httpClient: HTTPClient())
    
    public let baseURL: NSURL
    public let serializer: SerializerProtocol
    public let httpClient: HTTPClientProtocol
    public let headers: [String: String]
    
    public init(baseURL: NSURL, serializer: SerializerProtocol, httpClient: HTTPClientProtocol) {
        self.baseURL = baseURL
        self.serializer = serializer
        self.httpClient = httpClient
        self.headers = [:]
    }
}