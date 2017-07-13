//
//  JSONSerializer.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 10/8/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

public protocol ReflectionDiffType {
    var value1: Reflectable { get }
    var value2: Reflectable { get }
    var granular: Bool { get }
}

public struct Diff<T: Reflectable>: ReflectionDiffType {
    public let value1: Reflectable
    public let value2: Reflectable
    public let granular: Bool
    
    public init() {
        self.value1 = Reflection()
        self.value2 = Reflection()
        self.granular = true
    }
    
    public init(from value1: T, to value2: T, granular: Bool = true) {
        self.value1 = value1
        self.value2 = value2
        self.granular = granular
    }
}

public enum ReflectionJSONSerializerError: RetroluxError {
    case unsupportedType(type: Any.Type)
    case noData
    
    public var rl_error: RetroluxErrorDescription {
        switch self {
        case .unsupportedType(type: let type):
            return RetroluxErrorDescription(
                description: "The type given, \(type), is not supported.",
                suggestion: "Make sure to pass in an object that conforms to the \(Reflectable.self) protocol. The type given, \(type), does not conform to \(Reflectable.self)."
            )
        case .noData:
            return RetroluxErrorDescription(
                description: "The HTTP body was empty, but a response was expected.",
                suggestion: nil
            )
        }
    }
}

fileprivate protocol GetTypeFromArray {
    static func getReflectableType() -> Reflectable.Type?
}

extension Array: GetTypeFromArray {
    fileprivate static func getReflectableType() -> Reflectable.Type? {
        return Element.self as? Reflectable.Type
    }
}

public class ReflectionJSONSerializer: OutboundSerializer, InboundSerializer {
    open let reflector = Reflector.shared
    
    public init() {
        
    }
    
    public func supports(outboundType: Any.Type) -> Bool {
        if outboundType is ReflectionDiffType.Type {
            return true
        }
        if outboundType is Reflectable.Type {
            return true
        }
        return (outboundType as? GetTypeFromArray.Type)?.getReflectableType() != nil
    }
    
    public func supports(inboundType: Any.Type) -> Bool {
        if inboundType is Reflectable.Type {
            return true
        }
        return (inboundType as? GetTypeFromArray.Type)?.getReflectableType() != nil
    }
    
    public func validate(outbound: [BuilderArg]) -> Bool {
        return outbound.filter { supports(outboundType: $0.type) }.count == 1
    }
    
    public func makeValue<T>(from clientResponse: ClientResponse, type: T.Type) throws -> T {
        guard let data = clientResponse.data else {
            throw ReflectionJSONSerializerError.noData
        }
        
        if let reflectable = T.self as? Reflectable.Type {
            return try reflector.convert(fromJSONDictionaryData: data, to: reflectable) as! T
        } else if let array = T.self as? GetTypeFromArray.Type {
            guard let type = array.getReflectableType() else {
                throw ReflectionJSONSerializerError.unsupportedType(type: T.self)
            }
            return try reflector.convert(fromJSONArrayData: data, to: type) as! T
        } else {
            throw ReflectionJSONSerializerError.unsupportedType(type: T.self)
        }
    }
    
    public func apply(arguments: [BuilderArg], to request: inout URLRequest) throws {
        let arg = arguments.first!
        
        if let diff = arg.starting as? ReflectionDiffType {
            let dictionary = try reflector.diff(from: diff.value1, to: diff.value2, granular: diff.granular)
            let data = try JSONSerialization.data(withJSONObject: dictionary, options: [])
            request.httpBody = data
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        } else if let reflectable = arg.starting as? Reflectable {
            let dictionary = try reflector.convertToDictionary(from: reflectable)
            let data = try JSONSerialization.data(withJSONObject: dictionary, options: [])
            request.httpBody = data
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        } else if let array = arg.starting as? [Reflectable] {
            let dictionaries = try array.map { try reflector.convertToDictionary(from: $0) }
            let data = try JSONSerialization.data(withJSONObject: dictionaries, options: [])
            request.httpBody = data
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        } else {
            throw ReflectionJSONSerializerError.unsupportedType(type: arg.type)
        }
    }
}
