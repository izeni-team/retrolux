//
//  JSONSerializer.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 10/8/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation
import RetroluxReflector

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

public class ReflectionJSONSerializer: Serializer {
    public init() {
        
    }
    
    public func supports(type: Any.Type, args: [Any], direction: SerializerDirection) -> Bool {
        return type is Reflectable.Type || (type as? GetTypeFromArray.Type)?.getReflectableType() != nil
    }
    
    fileprivate let jsonReadingOptions = JSONSerialization.ReadingOptions.mutableContainers
    
    fileprivate func convert(from dictionary: [String: Any], to type: Reflectable.Type) throws -> Reflectable {
        let instance = type.init()
        let properties = try Reflector().reflect(instance)
        for property in properties {
            let rawValue = dictionary[property.mappedTo]
            try instance.set(value: rawValue, for: property)
        }
        return instance
    }
    
    fileprivate func convertToDictionary(_ instance: Reflectable) throws -> [String: Any] {
        var dictionary: [String: Any] = [:]
        let properties = try Reflector().reflect(instance)
        for property in properties {
            dictionary[property.mappedTo] = try instance.value(for: property)
        }
        return dictionary
    }
    
    public func makeValue<T>(from clientResponse: ClientResponse, type: T.Type) throws -> T {
        guard let data = clientResponse.data else {
            throw ReflectionJSONSerializerError.noData
        }
        
        if let reflectable = T.self as? Reflectable.Type {
            guard let dictionary = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any] else {
                throw ReflectionJSONSerializerError.invalidJSON
            }
            return try convert(from: dictionary, to: reflectable) as! T
        } else if let array = T.self as? GetTypeFromArray.Type {
            guard let type = array.getReflectableType() else {
                throw ReflectionJSONSerializerError.unsupportedType(type: T.self)
            }
            guard let array = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [[String: Any]] else {
                throw ReflectionJSONSerializerError.invalidJSON
            }
            return try array.map { try convert(from: $0, to: type) } as! T
        } else {
            throw ReflectionJSONSerializerError.unsupportedType(type: T.self)
        }
    }
    
    public func apply<T>(value input: T, to request: inout URLRequest) throws {
        if let reflectable = input as? Reflectable {
            let dictionary = try convertToDictionary(reflectable)
            let data = try JSONSerialization.data(withJSONObject: dictionary, options: [])
            request.httpBody = data
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        } else if let array = input as? [Reflectable] {
            let dictionaries = try array.map { try convertToDictionary($0) }
            let data = try JSONSerialization.data(withJSONObject: dictionaries, options: [])
            request.httpBody = data
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        } else {
            throw ReflectionJSONSerializerError.unsupportedType(type: T.self)
        }
    }
}
