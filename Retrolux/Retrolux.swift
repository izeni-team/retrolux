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
        return try NSJSONSerialization.dataWithJSONObject(object as! AnyObject, options: [])
    }
    
//    public func supportsType(type: Any.Type) -> Bool {
//        return type == [String: AnyObject].self
//    }
}

class User {}

// TODO: How to support return types for ReactiveCocoa?
public class Call<ResponseBody> {
    private let startCall: (call: Call<ResponseBody>) -> Void
    public let method: String
    public let url: NSURL
    public let body: NSData?
    public let headers: [String: String]
    var callback: (response: Response<ResponseBody>) -> Void
    
    // TODO: Add support for file uploading in background as multipart?
    public init(
        method: String,
        url: NSURL,
        body: NSData?,
        headers: [String: String],
        startCall: (call: Call<ResponseBody>) -> Void
        )
    {
        self.method = method
        self.url = url
        self.body = body
        self.headers = headers
        self.startCall = startCall
    }
    
    // TODO: Should we prevent calling this twice? What should the lifecycle of a call be?
    public func enqueue(callback: (response: Response<ResponseBody>) -> Void) -> Self {
        startCall(call: self)
        return self
    }
    
    public func perform() -> Response<ResponseBody> {
        var response: Response<ResponseBody>!
        let semaphore = dispatch_semaphore_create(0)
        enqueue { (asyncResponse) in
            dispatch_semaphore_signal(semaphore)
            response = asyncResponse
        }
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        return response!
    }
}

func test() {
    let r = Retrolux.sharedInstance
    let newUser = User()
    r.POST("/api/v1/users/", body: newUser, output: User.self)
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
    
    public func POST<Body, ResponseBody>(endpoint: String, body: Body, output: ResponseBody.Type) -> Call<ResponseBody> {
        return createCall("POST", endpoint: endpoint, body: nil, output: ResponseBody.self)
    }
    
    private func createCall<ResponseBody>(method: String, endpoint: String, body: NSData?, output: ResponseBody.Type) -> Call<ResponseBody> {
        let url = baseURL.URLByAppendingPathComponent(endpoint)
        return Call(httpClient: HTTPClient(), serializer: serializer, method: method, url: url, body: body, headers: headers, callbackHandler: { (httpResponse, callback) in
            if (200...299).contains(httpResponse.status ?? 0) {
                callback(response: Response<ResponseBody>.Success(body: <#T##Body#>))
            }
        })
    }
}