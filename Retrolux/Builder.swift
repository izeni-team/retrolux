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
    public var workerQueue: DispatchQueue
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
    open var workerQueue = DispatchQueue(
        label: "Retrolux.worker",
        qos: .background,
        attributes: .concurrent,
        autoreleaseFrequency: .inherit,
        target: nil
    )
    open var stateToCapture: RequestCapturedState {
        return RequestCapturedState(
            base: base,
            workerQueue: workerQueue
        )
    }
    open func outboundSerializers() -> [OutboundSerializer] {
        return serializers.flatMap { $0 as? OutboundSerializer }
    }
    
    open func inboundSerializers() -> [InboundSerializer] {
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
    
    open func interpret<T>(response: UninterpretedResponse<T>) -> InterpretedResponse<T> {
        // BuilderErrors are highest priority over other kinds of errors,
        // because they represent errors creating the request.
        if let error = response.error as? BuilderError {
            return .failure(error)
        }
        
        if !response.isHttpStatusOk {
            if response.urlResponse == nil, let error = response.error {
                return .failure(ResponseError.connectionError(error))
            }
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
            
            let enqueue: CallEnqueueFunction<ResponseType> = { (state, callback) in
                var request = URLRequest(url: state.base.appendingPathComponent(endpoint))
                request.httpMethod = method.rawValue
                
                do {
                    try self.applyArguments(
                        type: type,
                        state: state,
                        endpoint: endpoint,
                        method: method,
                        creation: creationArgs,
                        starting: startingArgs,
                        modifying: &request,
                        responseType: response
                    )
                    
                    self.requestInterceptor?(&request)
                    self.log(request: request)
                    
                    if self.isDryModeEnabled {
                        let provider = testProvider ?? { _ in ClientResponse(data: nil, response: nil, error: nil) }
                        let clientResponse = provider(creationArgs, startingArgs, request)
                        let response = self.process(immutableClientResponse: clientResponse, request: request, responseType: ResponseType.self)
                        self.log(response: response)
                        callback(response)
                    } else {
                        task = self.client.makeAsynchronousRequest(request: &request) { (clientResponse) in
                            state.workerQueue.async {
                                let response = self.process(immutableClientResponse: clientResponse, request: request, responseType: ResponseType.self)
                                self.log(response: response)
                                callback(response)
                            }
                        }
                        task!.resume()
                    }
                } catch {
                    let response = Response<ResponseType>(
                        request: request,
                        data: nil,
                        error: error,
                        urlResponse: nil,
                        body: nil,
                        interpreter: self.interpret
                    )
                    self.log(response: response)
                    callback(response)
                }
            }
            
            let cancel = { () -> Void in
                task?.cancel()
            }
            
            let capture = { self.stateToCapture }
            
            return self.callFactory.makeCall(capture: capture, enqueue: enqueue, cancel: cancel)
        }
    }
    
    func applyArguments<Args, ResponseType>(
        type: OutboundSerializerType,
        state: RequestCapturedState,
        endpoint: String,
        method: HTTPMethod,
        creation: Args,
        starting: Args,
        modifying request: inout URLRequest,
        responseType: ResponseType.Type
        ) throws
    {
        let outboundSerializers = self.outboundSerializers()
        let normalizedCreationArgs = self.normalize(arg: creation, serializerType: type, serializers: outboundSerializers) // Args used to create this request
        let normalizedStartingArgs = self.normalize(arg: starting, serializerType: type, serializers: outboundSerializers) // Args passed in when executing this request
        
        assert(normalizedCreationArgs.count == normalizedStartingArgs.count)
        
        var selfApplying: [BuilderArg] = []
        
        var serializer: OutboundSerializer?
        var serializerArgs: [BuilderArg] = []
        
        for (creation, starting) in zip(normalizedCreationArgs, normalizedStartingArgs) {
            assert((creation.serializer != nil) == (starting.serializer != nil), "Somehow normalize failed to produce the same results on both sides.")
            assert(creation.serializer == nil || creation.serializer === starting.serializer, "Normalize didn't produce the same serializer on both sides.")
            
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
                throw BuilderError.unsupportedArgument(arg)
            }
        }
        
        if let serializer = serializer {
            do {
                try serializer.apply(arguments: serializerArgs, to: &request)
            } catch {
                throw BuilderError.serializationError(serializer: serializer, error: error, arguments: serializerArgs)
            }
        }
        
        for arg in selfApplying {
            let type = arg.type as! SelfApplyingArg.Type
            type.apply(arg: arg, to: &request)
        }
    }
    
    func process<ResponseType>(immutableClientResponse: ClientResponse, request: URLRequest, responseType: ResponseType.Type) -> Response<ResponseType> {
        var clientResponse = immutableClientResponse
        self.responseInterceptor?(&clientResponse)
        
        let body: ResponseType?
        let error: Error?
        
        if let error = clientResponse.error {
            let response = Response<ResponseType>(
                request: request,
                data: clientResponse.data,
                error: error,
                urlResponse: clientResponse.response,
                body: nil,
                interpreter: self.interpret
            )
            return response
        }
        
        if ResponseType.self == Void.self {
            body = (() as! ResponseType)
            error = nil
        } else {
            if let serializer = inboundSerializers().first(where: { $0.supports(inboundType: ResponseType.self) }) {
                do {
                    body = try serializer.makeValue(from: clientResponse, type: ResponseType.self)
                    error = nil
                } catch let serializerError {
                    body = nil
                    error = BuilderResponseError.deserializationError(serializer: serializer, error: serializerError, clientResponse: clientResponse)
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
        
        return response
    }
}
