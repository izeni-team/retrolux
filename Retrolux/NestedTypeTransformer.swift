//
//  TypeTransformer.swift
//  Retrolux
//
//  Created by Bryan Henderson on 4/14/17.
//  Copyright © 2017 Bryan. All rights reserved.
//

import Foundation

class BottomTransformer<P, D>: TransformerType {
    func supports(propertyType: PropertyType) -> Bool {
        if case .unknown(let type) = propertyType.bottom {
            return type is P.Type
        }
        return false
    }
    
    func supports(value: Any) -> Bool {
        return type(of: value) is D.Type
    }
    
    func set(value: Any?, for property: Property, instance: Reflectable) throws {
        let transformed = transform(value: value, for: property, instance: instance)
        instance.set(value: transformed, for: property)
    }
    
    func transform(value: Any?, type: PropertyType, for property: Property, instance: Reflectable) -> Any? {
        switch type {
        case .anyObject:
            return value
        case .optional(let wrapped):
            return try transform(
                value: value,
                type: type,
                for: property,
                instance: instance
            )
            return try reflectable_transform(
                value: value,
                propertyName: propertyName,
                classType: classType,
                type: wrapped,
                transformer: transformer,
                direction: direction
            )
        case .bool:
            return value
        case .number:
            return value
        case .string:
            return value
        case .transformable(transformer: let transformer, targetType: let targetType):
            return try transformer.transform(value, targetType: targetType, direction: direction)
        case .array(let element):
            guard let array = value as? [Any] else {
                throw ValueTransformationError.typeMismatch(got: type(of: value))
            }
            return try array.map {
                try reflectable_transform(
                    value: $0,
                    propertyName: propertyName,
                    classType: classType,
                    type: element,
                    transformer: transformer,
                    direction: direction
                )
            }
        case .dictionary(let valueType):
            guard let dictionary = value as? [String: Any] else {
                // TODO: Add a test for this.
                throw ReflectorSerializationError.typeMismatch(expected: type, got: type(of: value), propertyName: propertyName, forClass: classType)
            }
            var result: [String: Any] = [:]
            for (key, value) in dictionary {
                result[key] = try reflectable_transform(
                    value: value,
                    propertyName: propertyName,
                    classType: classType,
                    type: valueType,
                    transformer: transformer,
                    direction: direction
                )
            }
            return result
        }
    }
    
    func value(for property: Property, instance: Reflectable) throws -> Any? {
        
    }
}
