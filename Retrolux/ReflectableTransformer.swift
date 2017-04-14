//
//  ReflectableTransformer.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 10/16/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

public class ReflectableTransformer: TransformerType {
    let reflector: Reflector
    
    public func supports(propertyType: PropertyType) -> Bool {
        if case .unknown(let type) = propertyType.bottom {
            return type is Reflectable.Type
        }
        return false
    }
    
    public func supports(value: Any) -> Bool {
        return value is [String: Any]
    }
    
    public init(reflector: Reflector) {
        self.reflector = reflector
    }
    
    public func set(value: Any?, for property: Property, instance targetInstance: Reflectable) throws {
        guard let value = value else {
            try targetInstance.set(value: nil, for: property)
            return
        }
        
        let protoType: Reflectable.Type
        if case .unknown(let type) = property.type.bottom {
            protoType = type as! Reflectable.Type
        } else {
            fatalError()
        }
//        let dictionary = value as! [String: Any]
//        
//        let instance = protoType.init()
//        let properties = try reflector.reflect(instance)
//        for property in properties {
//            try instance.set(value: dictionary[property.serializedName], for: property)
//        }
//        try targetInstance.set(value: instance, for: property)
    }
    
    public func value(for property: Property, instance: Reflectable) throws -> Any? {
        let value = instance.value(forKey: property.name)
        guard let object = value as? Reflectable else {
            if value != nil {
                throw ValueTransformationError.typeMismatch(got: type(of: value))
            } else {
                return nil
            }
        }
        var output: [String: Any] = [:]
        let properties = try reflector.reflect(object)
        for property in properties {
            output[property.serializedName] = try object.value(for: property) ?? NSNull()
        }
        return output
    }
}
