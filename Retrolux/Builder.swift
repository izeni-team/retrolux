//
//  Builder.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 8/21/17.
//  Copyright © 2017 Christopher Bryan Henderson. All rights reserved.
//

import Foundation

public enum Method {
    case get(String)
    case post(String)
    case delete(String)
    case put(String)
    case options(String)
    case head(String)
    case patch(String)
    
    public var path: String {
        switch self {
        case .get(let path), .post(let path), .delete(let path):
            return path
        case .put(let path), .options(let path), .head(let path):
            return path
        case .patch(let path):
            return path
        }
    }
    
    public var method: String {
        switch self {
        case .get:
            return "GET"
        case .post:
            return "POST"
        case .delete:
            return "DELETE"
        case .put:
            return "PUT"
        case .options:
            return "OPTIONS"
        case .head:
            return "HEAD"
        case .patch:
            return "PATCH"
        }
    }
}

public protocol BuilderEncoder {
    func supports<T>(type: T.Type) -> Bool
    func encode<T>(body: T) throws -> (contentType: String, body: Data)
}

public protocol BuilderDecoder {
    func supports<T>(type: T.Type) -> Bool
    func decode<T>(_ data: Data) throws -> T
}

public protocol Client {
    func start(_ request: URLRequest, _ callback: @escaping (ResponseData) -> Void) -> Call
}

// TODO: Make Path, Query, Header, etc. all conform to and implement this protocol.
public protocol BuilderArg {

/// ->
    // added throwing and removed static. (to avoid as! casting Self)
    func apply(starting: BuilderArg?, to request: inout URLRequest) throws
}
extension BuilderArg {
    // added to assert that a value cannot be nil
    func cannotBeNil(starting: BuilderArg?) throws -> Self {
        if let starting = starting as? Self {
            return starting
        } else {
            throw Builder.ParseArgumentError.startingCannotBeNil(Self.self)
        }
    }
    // added to cast to self easier.
    func asSelf(starting: BuilderArg?) throws -> Self? {
        if starting is Self? || starting is Self {
            return starting as? Self
        } else {
            throw Builder.ParseArgumentError.mismatchTypes(creation: Self.self, starting: type(of: starting))
        }
    }
}

public struct Query: BuilderArg {
    public let value: String
    
    public init(_ value: String) {
        self.value = value
    }
    
    public init(_ value: Int) {
        self.value = String(value)
    }
    
    public func apply(starting: BuilderArg?, to request: inout URLRequest) throws {
        let s = try asSelf(starting: starting)
        
        if let url = request.url {
            let toReplace = "%7B\(value)%7D"
            let newURL = URL(string: url.absoluteString.replacingOccurrences(of: toReplace, with: s?.value ?? ""))
            request.url = newURL
        }
    }
}

/// <-

extension URLSessionTask: Call {
    public var isCancelled: Bool {
        return state == .canceling
    }
}

open class URLSessionClient: Client {
    open func start(_ request: URLRequest, _ callback: @escaping (ResponseData) -> Void) -> Call {
        let session = URLSession(configuration: .default)
        let task = session.dataTask(with: request) { (data: Data?, urlResponse: URLResponse?, error: Error?) in
            let httpResponse = urlResponse as? HTTPURLResponse
            let headers = httpResponse?.allHeaderFields as? [String: String]
            let responseData = ResponseData(body: data, status: httpResponse?.statusCode, headers: headers, error: error)
            callback(responseData)
        }
        return task
    }
}

public struct Path: BuilderArg {
    
    public let value: String
    
    public init(_ value: String) {
        self.value = value
    }
    
    public init(_ value: Int) {
        self.value = String(value)
    }
    
    /// >
    public func apply(starting: BuilderArg?, to request: inout URLRequest) throws {
        let s = try self.cannotBeNil(starting: starting)
        
        if let url = request.url {
            let toReplace = "%7B\(self.value)%7D"
            let newURL = URL(string: url.absoluteString.replacingOccurrences(of: toReplace, with: s.value))
            request.url = newURL
        }
    }
}

public struct Header: BuilderArg {
    public let value: String
    
    public init(_ value: String) {
        self.value = value
    }
    
    public static func apply(creation: BuilderArg, starting: BuilderArg, to request: inout URLRequest) {
        let c = creation as! Header
        let s = starting as! Header
        request.setValue(s.value, forHTTPHeaderField: c.value)
    }
}

class DryClient: URLSessionClient {
    init(_ simulated: ResponseData) {
        self.simulated = simulated
    }
    
    let simulated: ResponseData
    override func start(_ request: URLRequest, _ callback: @escaping (ResponseData) -> Void) -> Call {
        callback(simulated)
        struct Dud: Call {
            var isCancelled: Bool = false
            mutating func cancel() {
                self.isCancelled = true
            }
        }
        return Dud()
    }
}

enum BuilderCreationError: Error {
    case unsupportedBuilderArg
    case unsupportedBodyType
}

extension Encodable {
    func encode() throws -> Data {
        return try JSONEncoder().encode(self)
    }
}

extension Decodable {
    static func decode(from data: Data) throws -> Any {
        return try JSONDecoder().decode(Self.self, from: data)
    }
}

open class Builder {
    class HackEncoder: Encodable {
        var encoder: Encoder!
        func encode(to encoder: Encoder) throws {
            self.encoder = encoder
        }
    }
    
    struct HackDecoder: Decodable {
        let decoder: Decoder
        init(from decoder: Decoder) throws {
            self.decoder = decoder
        }
    }
    
    open class JSONEncoder: Foundation.JSONEncoder, BuilderEncoder {
        open func supports<T>(type: T.Type) -> Bool {
            return type is Encodable.Type
        }
        
        public func encode<T>(body: T) throws -> (contentType: String, body: Data) {
            guard let encodable = body as? Encodable else {
                throw BuilderCreationError.unsupportedBodyType
            }
            
            return (
                contentType: "application/json",
                body: try encodable.encode()
            )
        }
    }
    
    open class JSONDecoder: Foundation.JSONDecoder, BuilderDecoder {
        open func supports<T>(type: T.Type) -> Bool {
            return type is Decodable.Type
        }
        
        open func decode<T>(_ data: Data) throws -> T {
            guard let decodableType = T.self as? Decodable.Type else {
                throw BuilderCreationError.unsupportedBodyType // TODO: Throw different error.
            }
            
            return try decodableType.decode(from: data) as! T
        }
    }
    
    open let workerQueue: DispatchQueue = DispatchQueue(label: "Retrolux")
    open let base: URL
    open var encoders: [BuilderEncoder]
    open var decoders: [BuilderDecoder]
    open var client: Client
    
    public init(base: URL) {
        self.base = base
        self.encoders = [JSONEncoder()]
        self.decoders = [JSONDecoder()]
        self.client = URLSessionClient()
    }
    
    open func test() {
        class User {}
        
        struct EncoderHint<Type, Encoder> {
            static func getType() -> Any.Type {
                return Type.self
            }
            
            static func getEncoderType() -> Any.Type {
                return Encoder.self
            }
        }
        
        typealias JSON<T> = EncoderHint<T, JSONEncoder>
        
        let request = make(.get("users/{id}/"), args: Path("id"), body: Void.self, response: Int.self)
        _ = request.enqueue((Path("id"), ())) { (response) in
            
        }
    }
    
    var depth = 0
    open func flatten(_ args: Any, type: Any.Type) throws -> [BuilderArg?] {
        return []
//        depth += 1
//        defer {
//            depth -= 1
//        }
//
//        let print = { (string: String) -> Void in
//            var d = self.depth
//            while d > 1 {
//                Swift.print("  ", separator: "", terminator: "")
//                d -= 1
//            }
//            Swift.print(string)
//        }
//
//        let type = Swift.type(of: creation)
//        print("type(of: creation): \(type), creation: \(creation), starting: \(starting)")
//
//        if creation is Void {
//            return []
//        }
//        if let arg = creation as? BuilderArg {
//            return [arg]
//        }
//        let mirror = Mirror(reflecting: args)
//        print("mirror.children.count: \(mirror.children.count)")
//        if mirror.children.isEmpty {
//            return []
////            throw BuilderCreationError.unsupportedBuilderArg
//        }
//        return try Mirror(reflecting: args).children.reduce([]) {
//            $0 + (try flattenBuilderArgs($1.value, type: Swift.type(of: $1.value)))
//        }
    }
    
    internal func decode(from data: Data) throws -> Void {
        return ()
    }
    
    internal func decode<R>(from data: Data) throws -> R {
        if R.self == Void.self {
            return () as! R
        }
        
        guard let decoder = decoders.first(where: { $0.supports(type: R.self) }) else {
            fatalError() // TODO: Error message or throw exception.
        }
        
        return try decoder.decode(data)
    }
    
    internal func encode(using body: Void) throws -> (contentType: String, body: Data)? {
        return nil
    }
    
    internal func encode<B>(using body: B) throws -> (contentType: String, body: Data)? {
        if B.self == Void.self {
            return nil
        }
        
        guard let encoder = encoders.first(where: { $0.supports(type: B.self) }) else {
            throw BuilderCreationError.unsupportedBodyType
        }
        
        return try encoder.encode(body: body)
    }
    
    enum ParseArgumentError: Error {
        case mismatchTypes(creation: Any.Type, starting: Any.Type)
        case valueNotBuilderArg(Any.Type)
        case startingCannotBeNil(Any.Type)
        case nilArgInCreation
    }
    
    /// ->
    
    func parseArguments<A>(creation: A, starting: A) throws -> [(BuilderArg, BuilderArg?)] {
        var array = [(BuilderArg, BuilderArg?)]()
        try _parseArguments(creation, starting, to: &array)
        return array
    }
    
    private func _parseArguments(_ creation: Any, _ starting: Any, to array: inout [(BuilderArg, BuilderArg?)]) throws {
        
        if isNil(creation) {
            throw ParseArgumentError.nilArgInCreation
        }
        
        if creation is Void {
            return
            
        } else if creation is BuilderArg {
            
            // cannot return or nested args won't have a chance to prepare the request
            if isNil(starting) {
                array.append((creation as! BuilderArg, nil))
                return
            }
            
            if let starting = starting as? BuilderArg {
                
                guard type(of: creation) == type(of: starting) else {
                    throw ParseArgumentError.mismatchTypes(creation: type(of: creation), starting: type(of: creation))
                }
                
                array.append((creation as! BuilderArg, starting))
                
            } else {
                throw ParseArgumentError.valueNotBuilderArg(type(of: starting))
            }
            
        } else if creation as Any? is BuilderArg? {
            
            
            let creation = (creation as! GetUnderyingValueFromOptional).getValue as! BuilderArg
            let starting = (starting as! GetUnderyingValueFromOptional).getValue
            
            if isNil(starting) {
                array.append((creation, nil))
            } else {
                guard type(of: creation) == type(of: starting) else {
                    throw ParseArgumentError.mismatchTypes(creation: type(of: creation), starting: type(of: starting))
                }
                array.append((creation, starting as? BuilderArg))
            }
            
        } else if let creation = creation as? [AnyHashable : Any], let starting = starting as? [AnyHashable : Any] {
            
            for (key, _creation) in creation {
                if let _starting = starting[key] {
                    try _parseArguments(_creation, _starting, to: &array)
                } else {
                    try _parseArguments(_creation, nil as Any? as Any, to: &array)
                }
            }
            
        } else if let creation = creation as? [Any], let starting = starting as? [Any] {
            
            for (index, creation) in creation.enumerated(){
                if index < starting.count {
                    try _parseArguments(creation, starting[index], to: &array)
                } else {
                    try _parseArguments(creation, nil as Any? as Any, to: &array)
                }
            }
            
        } else {
            
            let creationMirror = Mirror(reflecting: creation).children
            let startingMirror = Mirror(reflecting: starting).children.map {$0}
            
            guard creationMirror.count != 0 else {
                throw ParseArgumentError.valueNotBuilderArg(type(of: creation))
            }
            
            for (index, creation) in creationMirror.enumerated() {
                
                if index < startingMirror.count {
                    try _parseArguments(creation.value, startingMirror[index].value, to: &array)
                } else {
                    // still need to parse the left side arguments if the right side is nil.
                    try _parseArguments(creation.value, nil as Any? as Any, to: &array)
                }
            }
        }
    }
    
    /// <-
    
    internal func applyArguments<A, B, Q>(creationArgs: A, body: B.Type, requestArgs: Q, to request: inout URLRequest) throws
    {
        let startingArgs: A
        let body: B
        
        if Q.self == Void.self {
            startingArgs = () as! A
            body = () as! B
        } else if A.self == Void.self && B.self == Q.self {
            startingArgs = () as! A
            body = requestArgs as! B
        } else if A.self == Q.self && B.self == Void.self {
            startingArgs = requestArgs as! A
            body = () as! B
        } else {
            (startingArgs, body) = requestArgs as! (A, B)
        }
        
        // Process HTTP body first, so that arguments may override the Content-Type header if they so wish.
        let encoded = try self.encode(using: body)
        request.httpBody = encoded?.body
        request.setValue(encoded?.contentType, forHTTPHeaderField: "Content-Type")
        
        // Process non-HTTP body arguments
        let parsedArguments = try parseArguments(creation: creationArgs, starting: startingArgs)
        
        /// >
        for (creation, starting) in parsedArguments {
            try creation.apply(starting: starting, to: &request)
        }
    }
    
    enum ProcessResponseError: Error {
        case missingBody
    }
    
    internal func process<R>(_ d: ResponseData, request: URLRequest) throws -> Response<R> {
        if R.self == Void.self {
            return Response(status: d.status, body: () as? R, headers: d.headers, error: d.error, request: request)
        } else if let body = d.body {
            let body: R = try self.decode(from: body)
            return Response(status: d.status, body: body, headers: d.headers, error: d.error, request: request)
        } else {
            throw ProcessResponseError.missingBody
        }
    }
    
    internal func _make<A, B, R, Q>(_ method: Method, args creationArgs: A, body: B.Type, response: R.Type, requestArgs: Q.Type) -> Request<Q, Response<R>, Call> {
        let factory: (Request<Q, Response<R>, Call>, Q, ResponseData?, @escaping (Response<R>) -> Void) -> Call = { (r, q, s, c) -> Call in
            var request = r.data
            
            // TODO: Catch this exception
            try! self.applyArguments(creationArgs: creationArgs, body: B.self, requestArgs: q, to: &request)
            
            let client = s == nil ? self.client : DryClient(s!)
            return client.start(request, { (responseData) in
                let processed: Response<R>
                do {
                    processed = try self.process(responseData, request: request)
                } catch {
                    processed = Response(
                        status: responseData.status,
                        body: nil,
                        headers: responseData.headers,
                        error: responseData.error ?? error,
                        request: request
                    )
                }
                c(processed)
            })
        }
        
        let url = base.appendingPathComponent(method.path)
        var request = URLRequest(url: url)
        request.httpMethod = method.method
        return Request(data: request, simulatedResponse: nil, factory: factory)
    }
    
    open func make<A, B, R>(_ method: Method, args: A, body: B.Type, response: R.Type) -> Request<(A, B), Response<R>, Call> {
        return _make(method, args: args, body: body, response: response, requestArgs: (A, B).self)
    }

    open func make<A, R>(_ method: Method, args: A, response: R.Type) -> Request<A, Response<R>, Call> {
        return _make(method, args: args, body: Void.self, response: response, requestArgs: A.self)
    }
    
    open func make<B, R>(_ method: Method, body: B.Type, response: R.Type) -> Request<B, Response<R>, Call> {
        return _make(method, args: (), body: body, response: response, requestArgs: B.self)
    }

    open func make<R>(_ method: Method, response: R.Type) -> Request<Void, Response<R>, Call> {
        return _make(method, args: (), body: Void.self, response: response, requestArgs: Void.self)
    }
}

/// ->>

fileprivate protocol GetUnderyingValueFromOptional {
    var getValue: Any {get}
}

extension Optional: GetUnderyingValueFromOptional {
    var getValue: Any {
        if case .some(let value) = self {
            return value
        } else {
            
            return nil as Any? as Any
        }
    }
}

protocol CanBeNil {
    var isNil: Bool {get}
}

extension NSNull: CanBeNil { var isNil: Bool { return true } }
extension Optional: CanBeNil {
    var isNil: Bool {
        if case .some(let wrapped) = self {
            if let canBeNil = wrapped as? CanBeNil {
                return canBeNil.isNil
            } else {
                return false
            }
        } else {
            return true
        }
    }
}

func isNil(_ value: Any?) -> Bool {
    return value.isNil
}










