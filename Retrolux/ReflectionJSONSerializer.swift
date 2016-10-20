//
//  JSONSerializer.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 10/8/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation
import RetroluxReflector

enum ReflectionJSONSerializerError: Error {
    case reflectionError(error: ReflectionError)
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

class ReflectionJSONSerializer: Serializer {
    func supports(type: Any.Type) -> Bool {
        return type is Reflectable.Type || (type as? GetTypeFromArray.Type)?.getReflectableType() != nil
    }
    
    fileprivate let jsonReadingOptions = JSONSerialization.ReadingOptions.mutableContainers
    
    func makeValue<T>(from clientResponse: ClientResponse, type: T.Type) throws -> T {
        guard let data = clientResponse.data else {
            throw ReflectionJSONSerializerError.noData
        }
        
        if let reflectable = T.self as? Reflectable.Type {
            return () as! T
        } else if let array = T.self as? GetTypeFromArray.Type {
            guard let type = array.getReflectableType() else {
                throw ReflectionJSONSerializerError.unsupportedType(type: T.self)
            }
            let results = try Reflector().convert(fromJSONArrayData: data, to: Person.self)
            return results as! T
        } else {
            throw ReflectionJSONSerializerError.unsupportedType(type: T.self)
        }
    }
    
    func apply<T>(value input: T, to request: inout URLRequest) throws {
//        let values = normalizeValues(valueOrValues: input)
//        
//        var results: [[String: Any]] = []
//        
//        for object in values {
//            var json: [String: Any] = [:]
//            let properties = try Reflector().reflect(object)
//            for property in properties {
//                json[property.mappedTo] = try object.value(for: property)
//            }
//            results.append(json)
//        }
//        
//        let output: Any
//        if valueOrValues is GetTypeFromArray {
//            output = valueOrValues
//        } else {
//            output = results.first!
//        }
//        
//        let data = try JSONSerialization.data(withJSONObject: output, options: [])
//        request.httpBody = data
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }
}
