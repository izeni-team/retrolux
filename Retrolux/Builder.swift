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
    func makeRequest<A, T>(method: HTTPMethod, endpoint: String, args: A, response: Body<T>) -> (A) -> Call<T>
}

extension Builder {
    func isArg(arg: Any) -> Bool {
        if arg is AlignedSelfApplyingArg {
            return true
        } else if arg is SelfApplyingArg {
            return true
        } else if arg is BodyValues {
            return true
        }
        
        return false
    }
    
    func normalizeArgs<A>(args: A) -> [Any] {
        if isArg(arg: args) {
            return [args]
        } else {
            return Mirror(reflecting: args).children.map { $0.value }
        }
    }
    
    func makeRequest<A, T>(method: HTTPMethod, endpoint: String, args creationArgs: A, response: Body<T>) -> (A) -> Call<T> {
        return { startingArgs in
            var task: Task?
            var cancelled = false
            
            let start: (@escaping (Response<T>) -> Void) -> Void = { (callback) in
                if cancelled {
                    return
                }
                
                let url = self.baseURL.appendingPathComponent(endpoint)
                var request = URLRequest(url: url)
                request.httpMethod = method.rawValue
                
                let normalizedCreationArgs = self.normalizeArgs(args: creationArgs)
                let normalizedStartingArgs = self.normalizeArgs(args: startingArgs)
                
                for (index, arg) in normalizedStartingArgs.enumerated() {
                    if let arg = arg as? AlignedSelfApplyingArg {
                        let alignedArg = normalizedCreationArgs[index]
                        print("BEFORE:", request.url!.absoluteString)
                        arg.apply(to: &request, with: alignedArg)
                        print("AFTER:", request.url!.absoluteString)
                    } else if let arg = arg as? SelfApplyingArg {
                        arg.apply(to: &request)
                    } else if let body = arg as? BodyValues {
                        assert(self.serializer.supports(type: body.type), "Unsupported type: \(body.type)")
                        try! self.serializer.deserialize(from: body.value, modify: &request)
                    } else {
                        fatalError("Unsupported argument type: \(type(of: arg))")
                    }
                }
                
                task = self.client.makeAsynchronousRequest(request: request, callback: { (response) in
                    print("Status: \((response.response as? HTTPURLResponse)?.statusCode)")
                    let body: String
                    if let data = response.data {
                        body = String(data: data, encoding: .utf8)!
                    } else {
                        body = "<no_body>"
                    }
                    print("Body: \(body)")
                    
                    do {
                        let result: Result<T>
                        if T.self == Void.self {
                            result = Result<T>.success(value: () as! T)
                        } else {
                            result = Result<T>.success(value: try self.serializer.serialize(from: response))
                        }
                        let response = Response(request: request, rawResponse: response, result: result)
                        callback(response)
                    } catch let error {
                        print("Error serializing response: \(error)")
                        let result = Result<T>.failure(error: ErrorResponse(error: error))
                        let response = Response(request: request, rawResponse: response, result: result)
                        callback(response)
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
