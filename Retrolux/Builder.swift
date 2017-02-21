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
    
    public func normalize<A>(arg: A) -> [(Any?, Any.Type)] {
        if let wrapped = arg as? WrappedSerializerArg {
            if let value = wrapped.value {
                return normalize(arg: value)
            } else {
                return [(nil, wrapped.type)]
            }
        } else if let opt = arg as? OptionalHelper {
            if let value = opt.value {
                return normalize(arg: value)
            } else {
                return [(nil, opt.type)]
            }
        } else if isArg(arg: arg) {
            return [(arg, type(of: arg))]
        } else {
            return Mirror(reflecting: arg).children.map {
                let normalized = normalize(arg: $0.value)
                assert(normalized.count == 1, "Children of arguments may not have more than one child themselves. Depth must not exceed 2.")
                return normalized.first!
            }
        }
    }
    
    public func makeRequest<Args, ResponseType>(type: OutboundSerializerType = .auto, method: HTTPMethod, endpoint: String, args creationArgs: Args, response: ResponseType.Type) -> (Args) -> Call<ResponseType> {
        return { startingArgs in
            var task: Task?
            var cancelled = false
            
            let start: (@escaping (Response<ResponseType>) -> Void) -> Void = { (callback) in
                DispatchQueue.global().async {
                    if cancelled {
                        return
                    }
                    let url = self.baseURL.appendingPathComponent(endpoint)
                    var request = URLRequest(url: url)
                    request.httpMethod = method.rawValue
                    
                    let normalizedCreationArgs: [(Any?, Any.Type)] = self.normalize(arg: creationArgs) // Args used to create this request
                    let normalizedStartingArgs: [(Any?, Any.Type)] = self.normalize(arg: startingArgs) // Args passed in when executing this request
                    assert(normalizedCreationArgs.count == normalizedStartingArgs.count)
                    let builderArgs: [BuilderArg] = zip(normalizedCreationArgs, normalizedStartingArgs).map {
                        BuilderArg(type: $0.1, creation: $0.0, starting: $1.0)
                    }
                    
                    let serializerArgs = builderArgs.filter {
                        $0.type is SerializerArg.Type
                    }
                    
                    if !serializerArgs.isEmpty {
                        if let serializer = self.outboundSerializers.first(where: { type.isDesired(serializer: $0) && $0.supports(outbound: serializerArgs) }) {
                            do {
                                try serializer.apply(arguments: serializerArgs, to: &request)
                            } catch {
                                let result = Result<ResponseType>.failure(error: ErrorResponse(error: error))
                                let response = Response<ResponseType>(request: request, raw: nil, result: result)
                                DispatchQueue.main.async {
                                    callback(response)
                                }
                            }
                        }
                    }
                    
                    // Self applying arguments are always applied last, so as to allow the user to override the serializer's output.
                    for arg in builderArgs {
                        if let selfApplying = arg.type as? SelfApplyingArg.Type {
                            selfApplying.apply(arg: arg, to: &request)
                        }
                    }

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
