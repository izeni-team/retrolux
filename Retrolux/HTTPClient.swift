//
//  HTTPClient.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 7/15/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

// TODO: Add support for ignoring SSL errors.
public class HTTPClient: NSObject, Client, URLSessionDelegate, URLSessionTaskDelegate {
    public private(set) var session: URLSession!
    public var interceptor: ((inout URLRequest) -> Void)?
    
    public override init() {
        super.init()
        let configuration = URLSessionConfiguration.default
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }
    
    public func makeAsynchronousRequest(
        request: inout URLRequest,
        callback: @escaping (_ response: ClientResponse) -> Void
        ) -> Task
    {
        interceptor?(&request)
        
        let task = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) in
            callback(ClientResponse(data: data, response: response, error: error))
        }) 
        return HTTPTask(task: task)
    }
}
