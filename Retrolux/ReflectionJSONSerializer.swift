//
//  JSONSerializer.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 10/8/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

public enum ReflectionJSONSerializerError: Error {
    case unsupportedType(type: Any.Type)
    case noData
    case invalidJSON
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
            guard let dictionary = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any] else {
                throw ReflectionJSONSerializerError.invalidJSON
            }
            print(dictionary)
            return try reflector.convert(fromDictionary: dictionary, to: reflectable) as! T
        } else if let array = T.self as? GetTypeFromArray.Type {
            guard let type = array.getReflectableType() else {
                throw ReflectionJSONSerializerError.unsupportedType(type: T.self)
            }
            guard let array = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [[String: Any]] else {
                throw ReflectionJSONSerializerError.invalidJSON
            }
            return try array.map { try reflector.convert(fromDictionary: $0, to: type) } as! T
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
