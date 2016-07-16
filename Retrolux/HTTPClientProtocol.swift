//
//  HTTPClientProtocol.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 7/15/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

public typealias HTTPClientResponseData = (data: NSData?, status: Int?, headers: [String: String]?, error: NSError?)

public protocol HTTPClientProtocol: class {
    func makeAsynchronousRequest(method: String, URL: NSURL, body: NSData?, headers: [String: String], callback: HTTPClientResponseData -> Void) -> HTTPTaskProtocol
}

extension HTTPClientProtocol {
    // Converts async call into synchronous call.
    public func makeSynchronousRequest(method: String, URL: NSURL, body: NSData?, headers: [String: String]) -> HTTPClientResponseData {
        var response: HTTPClientResponseData?
        let semaphore = dispatch_semaphore_create(0)
        makeAsynchronousRequest(method, URL: URL, body: body, headers: headers, callback: { (data: NSData?, status: Int?, headers: [String: String]?, error: NSError?) -> Void in
            response = (data: data, status: status, headers: headers, error: error)
            dispatch_semaphore_signal(semaphore)
        }).resume()
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        return response!
    }
}