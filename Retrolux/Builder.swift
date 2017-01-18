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
    var serializers: [Serializer] { get }
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
    
    public func makeRequest<Args, ResponseType>(method: HTTPMethod, endpoint: String, args creationArgs: Args, response: Body<ResponseType>) -> (Args) -> Call<ResponseType> {
        return { startingArgs in
            var task: Task?
            var cancelled = false
            
            let start: (@escaping (Response<ResponseType>) -> Void) -> Void = { (callback) in
                DispatchQueue.global().async {
                    if cancelled {
                        return
                    }
                    
                    let url = URL(string: self.baseURL.absoluteString.removingPercentEncoding! + endpoint)!
                    var request = URLRequest(url: url)
                    request.httpMethod = method.rawValue
                    
                    let normalizedCreationArgs = self.normalizeArgs(args: creationArgs) // Args used to create this request
                    let normalizedStartingArgs = self.normalizeArgs(args: startingArgs) // Args passed in when executing this request
                    
                    do {
                        for (index, arg) in normalizedStartingArgs.enumerated() {
                            if let arg = arg as? AlignedSelfApplyingArg {
                                let alignedArg = normalizedCreationArgs[index]
                                arg.apply(to: &request, with: alignedArg)
                            } else if let arg = arg as? SelfApplyingArg {
                                arg.apply(to: &request)
                            } else if let body = arg as? BodyValues {
                                if let serializer = self.serializers.first(where: { $0.supports(type: body.type, args: normalizedStartingArgs, direction: .outbound) }) {
                                    try serializer.apply(value: body.value, to: &request)
                                } else {
                                    // This is incorrect usage of Retrolux, hence it is a fatal error.
                                    fatalError("Unsupported argument type when sending request: \(type(of: body.type))")
                                }
                            } else {
                                // This is incorrect usage of Retrolux, hence it is a fatal error.
                                fatalError("Unsupported argument type when sending request: \(type(of: arg))")
                            }
                        }
                        
                        task = self.client.makeAsynchronousRequest(request: request, callback: { (clientResponse) in
                            let result: Result<ResponseType>
                            let response: Response<ResponseType>
                            do {
                                if ResponseType.self == Void.self {
                                    result = .success(value: () as! ResponseType)
                                } else if let serializer = self.serializers.first(where: { $0.supports(type: ResponseType.self, args: normalizedStartingArgs, direction: .inbound) }) {
                                    result = .success(value: try serializer.makeValue(from: clientResponse, type: ResponseType.self))
                                } else {
                                    // This is incorrect usage of Retrolux, hence it is a fatal error.
                                    fatalError("Unsupported argument type when processing request: \(ResponseType.self)")
                                }
                                response = Response(request: request, raw: clientResponse, result: result)
                            } catch {
                                print("Error serializing response: \(error)")
                                result = .failure(error: ErrorResponse(error: error))
                                response = Response(request: request, raw: clientResponse, result: result)
                            }
                            
                            DispatchQueue.main.async {
                                callback(response)
                            }
                        })
                        task!.resume()
                    } catch {
                        let result = Result<ResponseType>.failure(error: ErrorResponse(error: error))
                        let response = Response<ResponseType>(request: request, raw: nil, result: result)
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
