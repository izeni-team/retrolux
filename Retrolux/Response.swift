//
//  Response.swift
//  Retrolux
//
//  Created by Mitchell Tenney on 9/12/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

public struct Response<T> {
    // Do we want the NSURLRequest or NSHTTPURLResponse?
    public let request: URLRequest
    public let data: Data?
    public let error: Error?
    public let urlResponse: URLResponse?
    public let body: T?
    internal let interpreter: (Response<T>) -> InterpretedResponse<T>
    
    public var interpreted: InterpretedResponse<T> {
        return interpreter(self)
    }
    
    public var isSuccessful: Bool {
        return body != nil && isHttpStatusOk
    }
    
    public var isHttpStatusOk: Bool {
        return (200...299).contains(status ?? 0)
    }
    
    public var httpUrlResponse: HTTPURLResponse? {
        return urlResponse as? HTTPURLResponse
    }
    
    public var status: Int? {
        return httpUrlResponse?.statusCode
    }
    
    public var headers: [String: String] {
        return (httpUrlResponse?.allHeaderFields as? [String: String]) ?? [:]
    }
}
