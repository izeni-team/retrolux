//
//  HTTPClient.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 7/15/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

// TODO: Add support for ignoring SSL errors.
class HTTPClient: Client {
    let session: URLSession
    var interceptor: ((inout URLRequest) -> Void)?
    
    init() {
        let configuration = URLSessionConfiguration.default
        session = URLSession(configuration: configuration)
    }
    
    func makeAsynchronousRequest(
        request inputRequest: URLRequest,
        callback: @escaping (_ response: ClientResponse) -> Void
        ) -> Task
    {
        var request = inputRequest
        self.interceptor?(&request)
                
        let task = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) in
            callback(ClientResponse(data: data, response: response, error: error))
        }) 
        return HTTPTask(task: task)
    }
}
