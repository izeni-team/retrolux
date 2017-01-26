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
    public var outboundSerializers: [OutboundSerializer] {
        return serializers.flatMap { $0 as? OutboundSerializer }
    }
    
    public var inboundSerializers: [InboundSerializer] {
        return serializers.flatMap { $0 as? InboundSerializer }
    }
    
    public func isArg(arg: Any) -> Bool {
        return arg is SelfApplyingArg || arg is SerializerArg
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
                    let url = self.baseURL.appendingPathComponent(endpoint)
                    print(url)
                    var request = URLRequest(url: url)
                    request.httpMethod = method.rawValue
                    
                    let normalizedCreationArgs: [Any] = self.normalizeArgs(args: creationArgs) // Args used to create this request
                    let normalizedStartingArgs: [Any] = self.normalizeArgs(args: startingArgs) // Args passed in when executing this request
                    assert(normalizedCreationArgs.count == normalizedStartingArgs.count)
                    let mergedArgs: [Any] = zip(normalizedCreationArgs, normalizedStartingArgs).map {
                        if $1 is MergeableArg {
                            var mergeable = $1 as! MergeableArg
                            mergeable.merge(with: $0)
                            return mergeable
                        }
                        return $1
                    }
                    
                    let wrappedSerializerArgs = mergedArgs.flatMap { $0 as? SerializerArg }
                    let unwrappedSerializerArgs: [Any] = wrappedSerializerArgs.map {
                        if let wrapped = $0 as? WrappedSerializerArg {
                            return wrapped.value
                        }
                        return $0
                    }
                    if let serializer = self.outboundSerializers.first(where: { $0.supports(outbound: unwrappedSerializerArgs) }) {
                        do {
                            try serializer.apply(arguments: unwrappedSerializerArgs, to: &request)
                        } catch {
                            let result = Result<ResponseType>.failure(error: ErrorResponse(error: error))
                            let response = Response<ResponseType>(request: request, raw: nil, result: result)
                            DispatchQueue.main.async {
                                callback(response)
                            }
                        }
                    }
                    
                    // Self applying arguments are always applied last, so as to allow the user to override the serializer's output.
                    let selfApplyingArgs = mergedArgs.flatMap { $0 as? SelfApplyingArg }
                    for arg in selfApplyingArgs {
                        arg.apply(to: &request)
                    }
                    
                    print(request.url!)
                    
                    task = self.client.makeAsynchronousRequest(request: request, callback: { (clientResponse) in
                        let result: Result<ResponseType>
                        let response: Response<ResponseType>
                        do {
                            if ResponseType.self == Void.self {
                                result = .success(value: () as! ResponseType)
                            } else if let serializer = self.inboundSerializers.first(where: { $0.supports(inboundType: ResponseType.self) }) {
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
