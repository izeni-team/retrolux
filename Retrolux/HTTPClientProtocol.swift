//
//  HTTPClientProtocol.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 7/15/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

public struct HTTPClientResponseData {
    public let data: NSData?
    public let status: Int?
    public let headers: [String: String]?
    public let error: NSError?
    
    public init(data: NSData?, status: Int?, headers: [String: String]?, error: NSError?) {
        self.data = data
        self.status = status
        self.headers = headers
        self.error = error
    }
}

public protocol HTTPClientProtocol: class {
    var interceptor: ((NSMutableURLRequest) -> Void)? { get set }
    
    func makeAsynchronousRequest(method: String, URL: NSURL, body: NSData?, headers: [String: String], callback: (httpResponse: HTTPClientResponseData) -> Void) -> HTTPTaskProtocol
}