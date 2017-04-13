//
//  Builder.swift
//  Retrolux
//
//  Created by Bryan Henderson on 1/26/17.
//  Copyright © 2017 Bryan. All rights reserved.
//

import Foundation

// State for each request is captured as soon as possible, instead of when it is needed.
// It is assumed that this behavior is more intuitive.
public struct RequestCapturedState {
    public var base: URL
}

open class Builder {
    private static let dryBase = URL(string: "e7c37c97-5483-4522-b400-106505fbf6ff/")!
    open class func dry() -> Builder {
        return Builder(base: self.dryBase)
    }
    
    open var base: URL
    open let isDryModeEnabled: Bool
    open var callFactory: CallFactory
    open var client: Client
    open var serializers: [Serializer]
    open var requestInterceptor: ((inout URLRequest) -> Void)?
    open var responseInterceptor: ((inout ClientResponse) -> Void)?
    open var stateToCapture: RequestCapturedState {
        return RequestCapturedState(
            base: base
        )
    }
    open var outboundSerializers: [OutboundSerializer] {
        return serializers.flatMap { $0 as? OutboundSerializer }
    }
    
    open var inboundSerializers: [InboundSerializer] {
        return serializers.flatMap { $0 as? InboundSerializer }
    }
    
    public init(base: URL) {
        self.base = base
        self.isDryModeEnabled = base == type(of: self).dryBase
        self.callFactory = HTTPCallFactory()
        self.client = HTTPClient()
        self.serializers = [
            ReflectionJSONSerializer(),
            MultipartFormDataSerializer(),
            URLEncodedSerializer()
        ]
        self.requestInterceptor = nil
        self.responseInterceptor = nil
    }
    
    open func log(request: URLRequest) {
        print("Retrolux: \(request.httpMethod!) \(request.url!.absoluteString.removingPercentEncoding!)")
    }
    
    open func log<T>(response: Response<T>) {
        let status = response.status ?? 0
        
        if response.error is BuilderError == false {
            let requestURL = response.request.url!.absoluteString.removingPercentEncoding!
            print("Retrolux: \(status) \(requestURL)")
        }
        
        if let error = response.error {
            if let localized = error as? LocalizedError {
                if let errorDescription = localized.errorDescription {
                    print("Retrolux: Error: \(errorDescription)")
                }
                if let recoverySuggestion = localized.recoverySuggestion {
                    print("Retrolux: Suggestion: \(recoverySuggestion)")
                }
                
                if localized.errorDescription == nil && localized.recoverySuggestion == nil {
                    print("Retrolux: Error: \(error)")
                }
            } else {
                print("Retrolux: Error: \(error)")
            }
        }
    }
    
    open func interpret<T>(response: Response<T>) -> InterpretedResponse<T> {
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
    
    private func normalize(arg: Any, serializerType: OutboundSerializerType, serializers: [OutboundSerializer]) -> [(serializer: OutboundSerializer?, value: Any?, type: Any.Type)] {
        if type(of: arg) == Void.self {
            return []
        } else if let wrapped = arg as? WrappedSerializerArg {
            if let value = wrapped.value {
                return normalize(arg: value, serializerType: serializerType, serializers: serializers)
            } else {
                return [(serializers.first(where: { serializerType.isDesired(serializer: $0) && $0.supports(outboundType: wrapped.type) }), nil, wrapped.type)]
            }
        } else if let opt = arg as? OptionalHelper {
            if let value = opt.value {
                return normalize(arg: value, serializerType: serializerType, serializers: serializers)
            } else {
                return [(serializers.first(where: { serializerType.isDesired(serializer: $0) && $0.supports(outboundType: opt.type) }), nil, opt.type)]
            }
        } else if arg is SelfApplyingArg {
            return [(nil, arg, type(of: arg))]
        } else if let serializer = serializers.first(where: { serializerType.isDesired(serializer: $0) && $0.supports(outboundType: type(of: arg)) }) {
            return [(serializer, arg, type(of: arg))]
        } else {
            let beneath = Mirror(reflecting: arg).children.reduce([]) {
                $0 + normalize(arg: $1.value, serializerType: serializerType, serializers: serializers)
            }
            if beneath.isEmpty {
                return [(nil, arg, type(of: arg))]
            } else {
                return beneath
            }
        }
    }
    
    open func makeRequest<Args, ResponseType>(type: OutboundSerializerType = .auto, method: HTTPMethod, endpoint: String, args creationArgs: Args, response: ResponseType.Type, testProvider: ((Args, Args, URLRequest) -> ClientResponse)? = nil) -> (Args) -> Call<ResponseType> {
        return { startingArgs in
            var task: Task?
            
            let perform: CallPerformFunction<ResponseType> = { (state) in
                let base = state.base
                let client = self.client
                let inboundSerializers = self.inboundSerializers
                let outboundSerializers = self.outboundSerializers
                let isDryModeEnabled = self.isDryModeEnabled
                let url = base.appendingPathComponent(endpoint)
                var request = URLRequest(url: url)
                request.httpMethod = method.rawValue
                
                let normalizedCreationArgs = self.normalize(arg: creationArgs, serializerType: type, serializers: outboundSerializers) // Args used to create this request
                let normalizedStartingArgs = self.normalize(arg: startingArgs, serializerType: type, serializers: outboundSerializers) // Args passed in when executing this request
                
                assert(normalizedCreationArgs.count == normalizedStartingArgs.count)
                
                var selfApplying: [BuilderArg] = []
                
                var serializer: OutboundSerializer?
                var serializerArgs: [BuilderArg] = []
                
                let createAndLogErrorResponse: (BuilderError) -> Response<ResponseType> = { error in
                    let response = Response<ResponseType>(
                        request: request,
                        data: nil,
                        error: error,
                        urlResponse: nil,
                        body: nil,
                        interpreter: self.interpret
                    )
                    self.log(response: response)
                    return response
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
                        } else {
                            // Serializer already set
                        }
                        
                        serializerArgs.append(arg)
                    } else {
                        return createAndLogErrorResponse(.unsupportedArgument(arg))
                    }
                }
                
                if let serializer = serializer {
                    do {
                        try serializer.apply(arguments: serializerArgs, to: &request)
                    } catch {
                        return createAndLogErrorResponse(.serializerError(serializer: serializer, error: error, arguments: serializerArgs))
                    }
                }
                
                for arg in selfApplying {
                    let type = arg.type as! SelfApplyingArg.Type
                    type.apply(arg: arg, to: &request)
                }
                
                self.requestInterceptor?(&request)
                self.log(request: request)
                
                let immutableClientResponse: ClientResponse
                if isDryModeEnabled {
                    let provider = testProvider ?? { _ in ClientResponse(data: nil, response: nil, error: nil) }
                    immutableClientResponse = provider(creationArgs, startingArgs, request)
                } else {
                    let semaphore = DispatchSemaphore(value: 0)
                    var clientResponse: ClientResponse!
                    task = client.makeAsynchronousRequest(request: &request) { (r) in
                        clientResponse = r
                        semaphore.signal()
                    }
                    task!.resume()
                    semaphore.wait()
                    immutableClientResponse = clientResponse
                }
                
                var clientResponse = immutableClientResponse
                self.responseInterceptor?(&clientResponse)
                
                let body: ResponseType?
                let error: Error?
                
                if ResponseType.self == Void.self {
                    body = (() as! ResponseType)
                    error = nil
                } else {
                    if let serializer = inboundSerializers.first(where: { $0.supports(inboundType: ResponseType.self) }) {
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
                
                self.log(response: response)
                
                return response
            }
            
            let cancel = { () -> Void in
                task?.cancel()
            }
            
            let capture = { self.stateToCapture }
            
            return self.callFactory.makeCall(capture: capture, perform: perform, cancel: cancel)
        }
    }
}
