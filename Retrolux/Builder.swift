//
//  Builder.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 10/8/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

protocol Builder {
    var baseURL: URL { get }
    var client: Client { get }
    var callFactory: CallFactory { get }
    var serializer: Serializer { get }
    func makeRequest<A, T>(method: Method, endpoint: String, args: A, response: T.Type) -> (A) -> Call<T>
    
//    func post<A, T>(_ endpoint: String, args: A, response: T.Type)
}

extension Builder {
    func makeRequest<A, T>(method: Method, endpoint: String, args: A, response: T.Type) -> (A) -> Call<T> {
        return { args in
            
            let url = self.baseURL.appendingPathComponent(endpoint)
            var request = URLRequest(url: url)
            request.httpMethod = method.rawValue
            
            if let arg = args as? Arg {
                arg.apply(to: &request)
            } else if self.serializer.supports(type: type(of: args)) {
                try! self.serializer.deserialize(from: args, modify: &request)
            } else {
                let mirror = Mirror(reflecting: args)
                for child in mirror.children {
                    if let arg = child.value as? Arg {
                        arg.apply(to: &request)
                    } else if self.serializer.supports(type: type(of: child.value)) {
                        try! self.serializer.deserialize(from: child.value, modify: &request)
                    } else {
                        fatalError("Unsupported argument type: \(type(of: child.value))")
                    }
                }
            }
            
            var task: Task?
            var cancelled = false
            
            print("URL:", request.url)
            print("Method:", request.httpMethod)
            print("Headers:", request.allHTTPHeaderFields)
            print("Body:", String(data: request.httpBody!, encoding: .utf8)!)
            
            let start: (@escaping (Response<T>) -> Void) -> Void = { (callback) in
                if cancelled {
                    return
                }
                
                task = self.client.makeAsynchronousRequest(request: request, callback: { (httpResponse) in
                    print("Status: \(httpResponse.status)")
                    let body: String
                    if let data = httpResponse.data {
                        body = String(data: data, encoding: .utf8)!
                    } else {
                        body = "<no_body>"
                    }
                    print("Body: \(body)")
                    
                    do {
                        let result = Result<T>.success(value: try self.serializer.serialize(from: httpResponse))
                        let response = Response(request: request, response: nil, rawResponse: nil, result: result)
                        callback(response)
                    } catch let error {
                        print("Error serializing response: \(error)")
                        callback(Response(request: request, response: nil, rawResponse: httpResponse.data, result: Result.error(error: ErrorResponse(rawResponse: httpResponse.data))))
                    }
                })
                task!.resume()
            }
            
            let cancel = { () -> Void in
                cancelled = true
                task?.cancel()
            }
            
            return self.callFactory.makeCall(start: start, cancel: cancel)
        }
    }
}
