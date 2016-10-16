//
//  JSONSerializer.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 10/8/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

enum RLObjectJSONSerializerError: Error {
    case unsupportedType(type: Any.Type)
    case noData
    case invalidJSON
}

fileprivate protocol GetTypeFromArray {
    static func getType() -> Any.Type
}

extension Array: GetTypeFromArray {
    fileprivate static func getType() -> Any.Type {
        return Element.self
    }
}

class RLObjectJSONSerializer: Serializer {
    func supports(type: Any.Type) -> Bool {
        return type is RLObjectProtocol.Type || (type as? GetTypeFromArray.Type)?.getType() is RLObjectProtocol.Type
    }
    
    fileprivate let jsonReadingOptions = JSONSerialization.ReadingOptions.mutableContainers
    
    func normalizeJSON(data: Data) throws -> [[String: Any]] {
        let json: Any
        do {
            json = try JSONSerialization.jsonObject(with: data, options: jsonReadingOptions)
        } catch {
            throw RLObjectJSONSerializerError.invalidJSON
        }
        
        if let array = json as? [[String: Any]] {
            return array
        } else if let dictionary = json as? [String: Any] {
            return [dictionary]
        } else {
            throw RLObjectJSONSerializerError.invalidJSON
        }
    }
    
    func normalizeValues(valueOrValues: Any) -> [RLObjectProtocol] {
        if valueOrValues is GetTypeFromArray {
            return valueOrValues as! [RLObjectProtocol]
        } else {
            let arr: [Any] = [valueOrValues]
            return arr as! [RLObjectProtocol]
        }
    }
    
    func serialize<T>(from clientResponse: ClientResponse) throws -> T {
        let type: RLObjectProtocol.Type
        if let array = T.self as? GetTypeFromArray.Type {
            if let t = array.getType() as? RLObjectProtocol.Type {
                type = t
            } else {
                throw RLObjectJSONSerializerError.unsupportedType(type: T.self)
            }
        } else {
            assert(T.self is RLObjectProtocol.Type)
            type = T.self as! RLObjectProtocol.Type
        }
        
        guard let data = clientResponse.data else {
            throw RLObjectJSONSerializerError.noData
        }
        
        var array: [Any] = []
        
        let normalizedJSONArray = try normalizeJSON(data: data)
        
        for dictionary in normalizedJSONArray {
            let serialized = type.init()
            
            let properties = try RLObjectReflector().reflect(serialized)
            
            for property in properties {
                try serialized.set(value: dictionary[property.mappedTo], for: property)
            }
            
            array.append(serialized)
        }
        
        if T.self is GetTypeFromArray.Type {
            return array as! T
        } else {
            return array.first as! T
        }
    }
    
    func deserialize<T>(from valueOrValues: T, modify request: inout URLRequest) throws {
        assert(self.supports(type: type(of: valueOrValues)))
        
        let values = normalizeValues(valueOrValues: valueOrValues)
        
        var results: [[String: Any]] = []
        
        for object in values {
            var json: [String: Any] = [:]
            let properties = try RLObjectReflector().reflect(object)
            for property in properties {
                json[property.mappedTo] = object.value(for: property)
            }
            results.append(json)
        }
        
        let output: Any
        if valueOrValues is GetTypeFromArray {
            output = valueOrValues
        } else {
            output = results.first!
        }
        
        let data = try JSONSerialization.data(withJSONObject: output, options: [])
        request.httpBody = data
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }
}
