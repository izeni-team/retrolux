//
//  JSONSerializer.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 10/8/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

enum RLObjectJSONSerializerError: Error {
    case noData
    case invalidJSON
}

extension RLObject: Body {}

class RLObjectJSONSerializer: Serializer {
    func supports(type: Any.Type) -> Bool {
        return type is RLObjectProtocol.Type
    }
    
    func serialize<T>(from clientResponse: ClientResponse) throws -> T {
        assert(T.self is RLObjectProtocol.Type, "Unsupported type \(T.self)--expected something that conforms to \(RLObjectProtocol.self)")
        let type = T.self as! RLObjectProtocol.Type
        
        guard let data = clientResponse.data else {
            throw RLObjectJSONSerializerError.noData
        }
        
        let serialized = type.init()
        
        guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            throw RLObjectJSONSerializerError.invalidJSON
        }
        
        let properties = try RLObjectReflector().reflect(serialized)
        
        for property in properties {
            try serialized.set(value: json[property.mappedTo], for: property)
        }
        
        return serialized as! T
    }
    
    func deserialize<T>(from value: T, modify request: inout URLRequest) throws {
        assert(value is RLObjectProtocol)
        let object = value as! RLObjectProtocol
        
        var json: [String: Any] = [:]
        let properties = try RLObjectReflector().reflect(object)
        for property in properties {
            json[property.mappedTo] = object.value(for: property)
        }
        
        let data = try JSONSerialization.data(withJSONObject: json, options: [])
        request.httpBody = data
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }
}
