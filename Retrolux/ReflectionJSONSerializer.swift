//
//  JSONSerializer.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 10/8/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

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
        return outboundType is Reflectable.Type || (outboundType as? GetTypeFromArray.Type)?.getReflectableType() != nil
    }
    
    public func supports(inboundType: Any.Type) -> Bool {
        return supports(outboundType: inboundType)
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
        
        if let reflectable = arg.starting as? Reflectable {
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
