//
//  Builder.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 10/8/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

public enum BuilderError: Error {
    case unsupportedArgument(BuilderArg)
    case tooManyMatchingSerializers(serializers: [OutboundSerializer], arguments: [BuilderArg])
    case validationError(serializer: Serializer, arguments: [BuilderArg])
}

public protocol Builder {
    var loggingComponents: [ClientLoggingComponent] { get }
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
    
    private func normalize(arg: Any, serializerType: OutboundSerializerType) -> [(serializer: OutboundSerializer?, value: Any?, type: Any.Type)] {
        if let wrapped = arg as? WrappedSerializerArg {
            if let value = wrapped.value {
                return normalize(arg: value, serializerType: serializerType)
            } else {
                return [(outboundSerializers.first(where: { serializerType.isDesired(serializer: $0) && $0.supports(outboundType: wrapped.type) }), nil, wrapped.type)]
            }
        } else if let opt = arg as? OptionalHelper {
            if let value = opt.value {
                return normalize(arg: value, serializerType: serializerType)
            } else {
                return [(outboundSerializers.first(where: { serializerType.isDesired(serializer: $0) && $0.supports(outboundType: opt.type) }), nil, opt.type)]
            }
        } else if arg is SelfApplyingArg {
            return [(nil, arg, type(of: arg))]
        } else if let serializer = outboundSerializers.first(where: { serializerType.isDesired(serializer: $0) && $0.supports(outboundType: type(of: arg)) }) {
            return [(serializer, arg, type(of: arg))]
        } else {
            let beneath = Mirror(reflecting: arg).children.reduce([]) {
                $0 + normalize(arg: $1.value, serializerType: serializerType)
            }
            if beneath.isEmpty {
                return [(nil, arg, type(of: arg))]
            } else {
                return beneath
            }
        }
    }
    
    public func makeRequest<Args, ResponseType>(type: OutboundSerializerType = .auto, method: HTTPMethod, endpoint: String, args creationArgs: Args, response: ResponseType.Type) -> (Args) -> Call<ResponseType> {
        let loggingComponents = self.loggingComponents
        
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
                    
                    let normalizedCreationArgs = self.normalize(arg: creationArgs, serializerType: type) // Args used to create this request
                    let normalizedStartingArgs = self.normalize(arg: startingArgs, serializerType: type) // Args passed in when executing this request
                    
                    assert(normalizedCreationArgs.count == normalizedStartingArgs.count)
                    
                    var selfApplying: [BuilderArg] = []
                    
                    var serializer: OutboundSerializer?
                    var serializerArgs: [BuilderArg] = []
                    
                    let execCallback: (Error) -> Void = { error in
                        let result = Result<ResponseType>.failure(error: ErrorResponse(error: error))
                        let response = Response<ResponseType>(request: request, raw: nil, result: result)
                        DispatchQueue.main.async {
                            callback(response)
                        }
                    }
                    
                    for (creation, starting) in zip(normalizedCreationArgs, normalizedStartingArgs) {
                        assert((creation.serializer != nil) == (starting.serializer != nil), "Somehow normalize failed to produce the same results on both sides.")
                        assert(creation.serializer == nil || creation.serializer === starting.serializer, "Normalize didn't produce the same serializer on both sides.")
                        assert(creation.type == starting.type, "Normalize determined a different type between creation and starting, which should be impossible.")
                        
                        let arg = BuilderArg(type: creation.type, creation: creation.value, starting: starting.value)
                        
                        if creation.type is SelfApplyingArg.Type {
                            selfApplying.append(arg)
                        } else if let thisSerializer = creation.serializer {
                            if serializer == nil {
                                serializer = thisSerializer
                            } else if serializer !== thisSerializer {
                                let serializers = [serializer!, thisSerializer]
                                execCallback(BuilderError.tooManyMatchingSerializers(serializers: serializers, arguments: serializerArgs + [arg]))
                                return
                            } else {
                                // Serializer already set
                            }
                            
                            serializerArgs.append(arg)
                        } else {
                            execCallback(BuilderError.unsupportedArgument(arg))
                            return
                        }
                    }
                    
                    do {
                        if let serializer = serializer {
                            if !serializer.validate(outbound: serializerArgs) {
                                execCallback(BuilderError.validationError(serializer: serializer, arguments: serializerArgs))
                                return
                            }
                            try serializer.apply(arguments: serializerArgs, to: &request)
                        }
                    } catch {
                        execCallback(error)
                        return
                    }
                    
                    for arg in selfApplying {
                        let type = arg.type as! SelfApplyingArg.Type
                        type.apply(arg: arg, to: &request)
                    }
                    
                    task = self.client.makeAsynchronousRequest(request: &request, logging: loggingComponents, callback: { (clientResponse) in
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
