//
//  HTTPClient.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 7/15/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

// WARNING: This isn't public, it's internal!
// Extensions declaring protocol conformance cannot be made public (at least in <= Swift 2.2).
extension NSURLSessionDataTask: HTTPTaskProtocol {}

// TODO: Add support for ignoring SSL errors.
class HTTPClient: HTTPClientProtocol {
    let session: NSURLSession
    
    init() {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        session = NSURLSession(configuration: configuration)
    }
    
    func makeAsynchronousRequest(method: String, URL: NSURL, body: NSData?, headers: [String : String], callback: (httpResponse: HTTPClientResponseData) -> Void) -> HTTPTaskProtocol {
        let request = NSMutableURLRequest()
        request.HTTPMethod = method
        request.HTTPBody = body
        request.allHTTPHeaderFields = headers
        request.URL = URL
        let task = session.dataTaskWithRequest(request) { (data: NSData?, response: NSURLResponse?, error: NSError?) in
            let httpResponse = (response as? NSHTTPURLResponse)
            let status = httpResponse?.statusCode
            let headers = httpResponse?.allHeaderFields as? [String: String]
            callback(httpResponse: HTTPClientResponseData(data: data, status: status, headers: headers, error: error))
        }
        return task
    }
}