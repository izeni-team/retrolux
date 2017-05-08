//
//  NestedTransformer.swift
//  Retrolux
//
//  Created by Bryan Henderson on 4/14/17.
//  Copyright © 2017 Bryan. All rights reserved.
//

import Foundation

public enum NestedTransformerError: RetroluxError {
    case typeMismatch(got: Any.Type, expected: Any.Type, propertyName: String, class: Any.Type, direction: NestedTransformerDirection)
    
    public var rl_error: RetroluxErrorDescription {
        switch self {
        case .typeMismatch(got: let got, expected: let expected, propertyName: let propertyName, class: let `class`, direction: let direction):
            
            let suggestion: String
            if direction == .serialize {
                suggestion = "Double check that the value set for '\(propertyName)' on \(`class`) contains an instance of type \(expected). The transformer, \(type(of: self)), reported that it doesn't support type \(got), which means the value set on the instance is incompatible."
            } else {
                suggestion = "Double check your data for '\(propertyName)' on \(`class`) to make sure that it contains a type that can be cast to \(expected). \(got) cannot be cast to \(expected)."
            }
            return RetroluxErrorDescription(
                description: "The transformer, \(type(of: self)), cannot convert type \(got) into type \(expected) for property '\(propertyName)' on \(`class`). Direction: \(direction.description).",
                suggestion: suggestion
            )
        }
    }
}

public enum NestedTransformerDirection {
    case serialize
    case deserialize
    
    var description: String {
        switch self {
        case .serialize:
            return "serialize"
        case .deserialize:
            return "deserialize"
        }
    }
}

public protocol NestedTransformer: TransformerType {
    associatedtype TypeOfProperty
    associatedtype TypeOfData
    
    func setter(_ dataValue: TypeOfData, type: Any.Type) throws -> TypeOfProperty
    func getter(_ propertyValue: TypeOfProperty) throws -> TypeOfData
}

extension NestedTransformer {
    public func supports(propertyType: PropertyType) -> Bool {
        switch propertyType.bottom {
        case .any:
            return false
        case .anyObject:
            return false
        case .array(_):
            return false
        case .dictionary(_):
            return false
        case .optional(_):
            return false
        case .unknown(let type):
            return type is TypeOfProperty.Type
        case .bool:
            return Bool.self is TypeOfProperty.Type
        case .number(let innerType):
            return innerType is TypeOfProperty.Type
        case .string:
            return String.self is TypeOfProperty.Type
        }
    }
    
    public func set(value: Any?, for property: Property, instance: Reflectable) throws {
        let transformed = try transform(
            value: value,
            type: property.type,
            for: property,
            instance: instance,
            direction: .deserialize
        )
        instance.setValue(transformed, forKey: property.name)
    }
    
    public func transform(value: Any?, type: PropertyType, for property: Property, instance: Reflectable, direction: NestedTransformerDirection) throws -> Any? {
        guard let value = value else {
            return nil
        }
                
        guard value is NSNull == false else {
            return nil
        }
        
        switch type {
        case .anyObject, .any, .bool, .number, .string:
            switch direction {
            case .deserialize:
                if let cast = value as? TypeOfData {
                    return try setter(cast, type: type(of: value))
                }
            case .serialize:
                if let cast = value as? TypeOfProperty {
                    return try getter(cast)
                }
            }
            throw NestedTransformerError.typeMismatch(
                got: type(of: value),
                expected: TypeOfProperty.self,
                propertyName: property.name,
                class: type(of: instance),
                direction: direction
            )
        case .optional(let wrapped):
            return try transform(
                value: value,
                type: wrapped,
                for: property,
                instance: instance,
                direction: direction
            )
        case .unknown(let unknownType):
            switch direction {
            case .serialize:
                if let cast = value as? TypeOfProperty {
                    return try getter(cast)
                } else {
                    throw NestedTransformerError.typeMismatch(
                        got: type(of: value),
                        expected: TypeOfProperty.self,
                        propertyName: property.name,
                        class: type(of: instance),
                        direction: direction
                    )
                }
            case .deserialize:
                if let cast = value as? TypeOfData {
                    return try setter(cast, type: unknownType)
                } else {
                    throw NestedTransformerError.typeMismatch(
                        got: type(of: value),
                        expected: TypeOfData.self,
                        propertyName: property.name,
                        class: type(of: instance),
                        direction: direction
                    )
                }
            }
        case .array(let inner):
            guard let array = value as? [Any] else {
                throw NestedTransformerError.typeMismatch(
                    got: type(of: value),
                    expected: [Any].self,
                    propertyName: property.name,
                    class: type(of: instance),
                    direction: direction
                )
            }
            return try array.map {
                try transform(
                    value: $0,
                    type: inner,
                    for: property,
                    instance: instance,
                    direction: direction
                )
            }
        case .dictionary(let inner):
            guard let dictionary = value as? [String: Any] else {
                // TODO: Add a test for this.
                throw NestedTransformerError.typeMismatch(
                    got: type(of: value),
                    expected: [String: Any].self,
                    propertyName: property.name,
                    class: type(of: instance),
                    direction: direction
                )
            }
            var result: [String: Any] = [:]
            for (key, value) in dictionary {
                result[key] = try transform(
                    value: value,
                    type: inner,
                    for: property,
                    instance: instance,
                    direction: direction
                )
            }
            return result
        }
    }
    
    public func value(for property: Property, instance: Reflectable) throws -> Any? {
        let raw = instance.value(forKey: property.name)
        let transformed = try transform(
            value: raw,
            type: property.type,
            for: property,
            instance: instance,
            direction: .serialize
        )
        return transformed
    }
}
