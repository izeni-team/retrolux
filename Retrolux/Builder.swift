//
//  Builder.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 10/8/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

public protocol Builder {
    var baseURL: URL { get }
    var client: Client { get }
    var callFactory: CallFactory { get }
    var serializer: Serializer { get }
    func makeRequest<A, T>(method: HTTPMethod, endpoint: String, args: A, response: Body<T>) -> (A) -> Call<T>
}

extension Builder {
    public func isArg(arg: Any) -> Bool {
        if arg is AlignedSelfApplyingArg {
            return true
        } else if arg is SelfApplyingArg {
            return true
        } else if arg is BodyValues {
            return true
        }
        
        return false
    }
    
    public func normalizeArgs<A>(args: A) -> [Any] {
        if isArg(arg: args) {
            return [args]
        } else {
            return Mirror(reflecting: args).children.map { $0.value }
        }
    }
    
    public func makeRequest<A, T>(method: HTTPMethod, endpoint: String, args creationArgs: A, response: Body<T>) -> (A) -> Call<T> {
        return { startingArgs in
            var task: Task?
            var cancelled = false
            
            let start: (@escaping (Response<T>) -> Void) -> Void = { (callback) in
                DispatchQueue.global().async {
                    if cancelled {
                        return
                    }
                    
                    let url = self.baseURL.appendingPathComponent(endpoint)
                    var request = URLRequest(url: url)
                    request.httpMethod = method.rawValue
                    
                    let normalizedCreationArgs = self.normalizeArgs(args: creationArgs)
                    let normalizedStartingArgs = self.normalizeArgs(args: startingArgs)
                    
                    do {
                        for (index, arg) in normalizedStartingArgs.enumerated() {
                            if let arg = arg as? AlignedSelfApplyingArg {
                                let alignedArg = normalizedCreationArgs[index]
                                arg.apply(to: &request, with: alignedArg)
                            } else if let arg = arg as? SelfApplyingArg {
                                arg.apply(to: &request)
                            } else if let body = arg as? BodyValues {
                                assert(self.serializer.supports(type: body.type), "Unsupported type: \(body.type)")
                                try self.serializer.apply(value: body.value, to: &request)
                            } else {
                                fatalError("Unsupported argument type: \(type(of: arg))")
                            }
                        }
                        
                        task = self.client.makeAsynchronousRequest(request: request, callback: { (clientResponse) in
                            let result: Result<T>
                            let response: Response<T>
                            do {
                                if T.self == Void.self {
                                    result = .success(value: () as! T)
                                } else {
                                    assert(self.serializer.supports(type: T.self))
                                    result = .success(value: try self.serializer.makeValue(from: clientResponse, type: T.self))
                                }
                                response = Response(request: request, rawResponse: clientResponse, result: result)
                            } catch {
                                print("Error serializing response: \(error)")
                                result = .failure(error: ErrorResponse(error: error))
                                response = Response(request: request, rawResponse: clientResponse, result: result)
                            }
                            
                            DispatchQueue.main.async {
                                callback(response)
                            }
                        })
                        task!.resume()
                    } catch {
                        let result = Result<T>.failure(error: ErrorResponse(error: error))
                        let response = Response<T>(request: request, rawResponse: nil, result: result)
                        DispatchQueue.main.async {
                            callback(response)
                        }
                    }
                }
            }
            
            let cancel = { () -> Void in
                cancelled = true
                task?.cancel()
            }
            
            return self.callFactory.makeCall(start: start, cancel: cancel)
        }
    }
}
