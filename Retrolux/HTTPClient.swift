//
//  HTTPClient.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 7/15/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

// TODO: Add support for ignoring SSL errors.
open class HTTPClient: NSObject, Client, URLSessionDelegate, URLSessionTaskDelegate {
    open var session: URLSession!
    
    public override init() {
        super.init()
        session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }
    
    open func makeAsynchronousRequest(
        request: inout URLRequest,
        callback: @escaping (_ response: ClientResponse) -> Void
        ) -> Task
    {
        let task = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) in
            let clientResponse = ClientResponse(data: data, response: response, error: error)
            callback(clientResponse)
        }) 
        return HTTPTask(task: task)
    }
}
