//
//  Response.swift
//  Retrolux
//
//  Created by Mitchell Tenney on 9/12/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

public class UninterpretedResponse<T> {
    // Do we want the NSURLRequest or NSHTTPURLResponse?
    public let request: URLRequest
    public let data: Data?
    public let error: Error?
    public let urlResponse: URLResponse?
    public let body: T?
    
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
    
    public init(
        request: URLRequest,
        data: Data?,
        error: Error?,
        urlResponse: URLResponse?,
        body: T?
        )
    {
        self.request = request
        self.data = data
        self.error = error
        self.urlResponse = urlResponse
        self.body = body
    }
}

public class Response<T>: UninterpretedResponse<T> {
    // Do we want the NSURLRequest or NSHTTPURLResponse?
    public let interpreted: InterpretedResponse<T>
    
    internal convenience init(
        request: URLRequest,
        data: Data?,
        error: Error?,
        urlResponse: URLResponse?,
        body: T?,
        interpreter: (UninterpretedResponse<T>) -> InterpretedResponse<T>
        )
    {
        let uninterpreted = UninterpretedResponse(
            request: request,
            data: data,
            error: error,
            urlResponse: urlResponse,
            body: body
        )
        self.init(
            request: request,
            data: data,
            error: error,
            urlResponse: urlResponse,
            body: body,
            interpreted: interpreter(uninterpreted)
        )
    }
    
    public init(
        request: URLRequest,
        data: Data?,
        error: Error?,
        urlResponse: URLResponse?,
        body: T?,
        interpreted _interpreted: InterpretedResponse<T>
    )
    {
        interpreted = _interpreted
        super.init(
            request: request,
            data: data,
            error: error,
            urlResponse: urlResponse,
            body: body
        )
    }
}
