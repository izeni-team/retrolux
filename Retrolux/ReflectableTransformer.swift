//
//  ReflectableTransformer.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 10/16/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

public class ReflectableTransformer: ValueTransformer {
    let reflector: Reflector
    
    public init(reflector: Reflector) {
        self.reflector = reflector
    }
    
    public func supports(targetType: Any.Type) -> Bool {
        return targetType is Reflectable.Type
    }
    
    public func supports(value: Any, targetType: Any.Type, direction: ValueTransformerDirection) -> Bool {
        switch direction {
        case .forwards:
            return value is [String: Any]
        case .backwards:
            return value is Reflectable
        }
    }
    
    public func transform(_ value: Any, targetType: Any.Type, direction: ValueTransformerDirection) throws -> Any {
        switch direction {
        case .forwards:
            // TODO: Need target type to be able to code.
            let protoType = targetType as! Reflectable.Type
            let dictionary = value as! [String: Any]
            
            let instance = protoType.init()
            let properties = try reflector.reflect(instance)
            for property in properties {
                try instance.set(value: dictionary[property.mappedTo], for: property)
            }
            return instance
        case .backwards:
            guard let object = value as? Reflectable else {
                throw ValueTransformationError.typeMismatch(got: type(of: value))
            }
            var output: [String: Any] = [:]
            let properties = try reflector.reflect(object)
            for property in properties {
                output[property.mappedTo] = try object.value(for: property) ?? NSNull()
            }
            return output
        }
    }
}
