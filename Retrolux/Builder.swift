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
    case serializationError(serializer: Serializer, error: Error, arguments: [BuilderArg])
}

public protocol Builder {
    var baseURL: URL { get }
    var client: Client { get }
    var callFactory: CallFactory { get }
    var serializers: [Serializer] { get }
    var requestInterceptor: ((inout URLRequest) -> Void)? { get }
    var responseInterceptor: ((inout ClientResponse) -> Void)? { get }
}

extension Builder {
    public var outboundSerializers: [OutboundSerializer] {
        return serializers.flatMap { $0 as? OutboundSerializer }
    }
    
    public var inboundSerializers: [InboundSerializer] {
        return serializers.flatMap { $0 as? InboundSerializer }
    }
    
    private func normalize(arg: Any, serializerType: OutboundSerializerType) -> [(serializer: OutboundSerializer?, value: Any?, type: Any.Type)] {
        if type(of: arg) == Void.self {
            return []
        } else if let wrapped = arg as? WrappedSerializerArg {
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
    
    public func log(request: URLRequest) {
        print("Retrolux: \(request.httpMethod!) \(request.url!.absoluteString.removingPercentEncoding!)")
    }
    
    public func log<T>(response: Response<T>) {
        let status = response.status ?? 0
        
        if response.error is BuilderError == false {
            let requestURL = response.request.url!.absoluteString.removingPercentEncoding!
            print("Retrolux: \(status) \(requestURL)")
        }
        
        if let error = response.error {
            print("Retrolux: Error: \(error)")
        }
    }
    
    public func interpret<T>(response: Response<T>) -> InterpretedResponse<T> {
        return defaultInterpreter(response: response)
    }
    
    public func defaultInterpreter<T>(response: Response<T>) -> InterpretedResponse<T> {
        // BuilderErrors are highest priority over other kinds of errors,
        // because they represent errors creating the request.
        if let error = response.error as? BuilderError {
            return .failure(error)
        }
        
        if !response.isHttpStatusOk {
            return .failure(ResponseError.invalidHttpStatusCode(code: response.status))
        }
        
        if let error = response.error {
            return .failure(error)
        }
        
        if let body = response.body {
            return .success(body)
        } else {
            assert(false, "This should be impossible.")
            return .failure(NSError(domain: "Retrolux.Error", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to serialize response for an unknown reason."]))
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
                    
                    let normalizedCreationArgs = self.normalize(arg: creationArgs, serializerType: type) // Args used to create this request
                    let normalizedStartingArgs = self.normalize(arg: startingArgs, serializerType: type) // Args passed in when executing this request
                    
                    assert(normalizedCreationArgs.count == normalizedStartingArgs.count)
                    
                    var selfApplying: [BuilderArg] = []
                    
                    var serializer: OutboundSerializer?
                    var serializerArgs: [BuilderArg] = []
                    
                    let execCallback: (BuilderError) -> Void = { error in
                        let response = Response<ResponseType>(
                            request: request,
                            data: nil,
                            error: error,
                            urlResponse: nil,
                            body: nil,
                            interpreter: self.interpret
                        )
                        DispatchQueue.main.async {
                            self.log(response: response)
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
                                execCallback(.tooManyMatchingSerializers(serializers: serializers, arguments: serializerArgs + [arg]))
                                return
                            } else {
                                // Serializer already set
                            }
                            
                            serializerArgs.append(arg)
                        } else {
                            execCallback(.unsupportedArgument(arg))
                            return
                        }
                    }
                    
                    if let serializer = serializer {
                        if !serializer.validate(outbound: serializerArgs) {
                            execCallback(.validationError(serializer: serializer, arguments: serializerArgs))
                            return
                        }
                        
                        do {
                            try serializer.apply(arguments: serializerArgs, to: &request)
                        } catch {
                            execCallback(.serializationError(serializer: serializer, error: error, arguments: serializerArgs))
                            return
                        }
                    }
                    
                    for arg in selfApplying {
                        let type = arg.type as! SelfApplyingArg.Type
                        type.apply(arg: arg, to: &request)
                    }
                    
                    self.requestInterceptor?(&request)
                    self.log(request: request)
                    
                    task = self.client.makeAsynchronousRequest(request: &request, callback: { (immutableClientResponse) in
                        var clientResponse = immutableClientResponse
                        self.responseInterceptor?(&clientResponse)
                        
                        let body: ResponseType?
                        let error: Error?
                        
                        if ResponseType.self == Void.self {
                            body = nil
                            error = nil
                        } else {
                            if let serializer = self.inboundSerializers.first(where: { $0.supports(inboundType: ResponseType.self) }) {
                                do {
                                    body = try serializer.makeValue(from: clientResponse, type: ResponseType.self)
                                    error = nil
                                } catch let serializerError {
                                    body = nil
                                    error = serializerError
                                }
                            } else {
                                // This is incorrect usage of Retrolux, hence it is a fatal error.
                                fatalError("Unsupported argument type when processing request: \(ResponseType.self)")
                            }
                        }
                        
                        let response: Response<ResponseType> = Response(
                            request: request,
                            data: clientResponse.data,
                            error: error ?? clientResponse.error,
                            urlResponse: clientResponse.response,
                            body: body,
                            interpreter: self.interpret
                        )
                        
                        DispatchQueue.main.async {
                            self.log(response: response)
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
