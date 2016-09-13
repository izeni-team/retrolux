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
extension URLSessionDataTask: HTTPTaskProtocol {}

// TODO: Add support for ignoring SSL errors.
class HTTPClient: HTTPClientProtocol {
    let session: URLSession
    var interceptor: ((inout URLRequest) -> Void)?
    
    init() {
        let configuration = URLSessionConfiguration.default
        session = URLSession(configuration: configuration)
    }
    func makeAsynchronousRequest(_ method: String, url: URL, body: Data?, headers: [String : String], callback: @escaping (_ httpResponse: HTTPClientResponseData) -> Void) -> HTTPTaskProtocol {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        request.allHTTPHeaderFields = headers
        
        self.interceptor?(&request)
        
        let task = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) in
            let httpResponse = (response as? HTTPURLResponse)
            let status = httpResponse?.statusCode
            let headers = httpResponse?.allHeaderFields as? [String : String]
            callback(HTTPClientResponseData(data: data, status: status, headers: headers, error: error))
        }) 
        return task
    }
}
