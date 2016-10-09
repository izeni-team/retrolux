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
        callback: @escaping (_ httpResponse: ClientResponse) -> Void
        ) -> Task
    {
        var request = inputRequest
        self.interceptor?(&request)
        
        print("\(request.httpMethod!) \(request.url!)")
        
        let task = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) in
            let httpResponse = (response as? HTTPURLResponse)
            let status = httpResponse?.statusCode
            print("HTTP Status: \(status)")
            let headers = httpResponse?.allHeaderFields as? [String : String]
            callback(ClientResponse(data: data, status: status, headers: headers, error: error))
        }) 
        return HTTPTask(task: task)
    }
}
