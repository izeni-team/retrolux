//
//  NestedTransformer.swift
//  Retrolux
//
//  Created by Bryan Henderson on 4/14/17.
//  Copyright © 2017 Bryan. All rights reserved.
//

import Foundation

open class NestedTransformer<P, D>: TransformerType {
    public enum Error: RetroluxError {
        case typeMismatch(got: Any.Type, expected: Any.Type, propertyName: String, class: Any.Type, direction: Direction)
        
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
    
    public enum Direction {
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
    
    open let setter: (D, Any.Type) throws -> P
    open let getter: (P) throws -> D
    
    public init(setter: @escaping (D, Any.Type) throws -> P, getter: @escaping (P) throws -> D) {
        self.setter = setter
        self.getter = getter
    }
    
    open func supports(propertyType: PropertyType) -> Bool {
        print("supports \(propertyType)")
        if case .unknown(let type) = propertyType.bottom {
            return type is P || type is P.Type
        }
        return false
    }
    
    open func supports(value: Any) -> Bool {
        return type(of: value) is D.Type
    }
    
    open func set(value: Any?, for property: Property, instance: Reflectable) throws {
        let transformed = try transform(
            value: value,
            type: property.type,
            for: property,
            instance: instance,
            direction: .deserialize
        )
        instance.setValue(transformed, forKey: property.name)
    }
    
    open func transform(value: Any?, type: PropertyType, for property: Property, instance: Reflectable, direction: Direction) throws -> Any? {
        guard let value = value else {
            return nil
        }
        
        switch type {
        case .anyObject, .any:
            return value
        case .optional(let wrapped):
            return try transform(
                value: value,
                type: wrapped,
                for: property,
                instance: instance,
                direction: direction
            )
        case .bool:
            return value
        case .number:
            return value
        case .string:
            return value
        case .unknown(let unknownType):
            switch direction {
            case .serialize:
                if let cast = value as? P {
                    let thing = try getter(cast)
                    print("thing: \(thing)")
                    return thing
                } else {
                    throw Error.typeMismatch(
                        got: type(of: value),
                        expected: P.self,
                        propertyName: property.name,
                        class: type(of: instance),
                        direction: direction
                    )
                }
            case .deserialize:
                if let cast = value as? D {
                    return try setter(cast, unknownType)
                } else {
                    throw Error.typeMismatch(
                        got: type(of: value),
                        expected: D.self,
                        propertyName: property.name,
                        class: type(of: instance),
                        direction: direction
                    )
                }
            }
        case .array(let inner):
            guard let array = value as? [Any] else {
                throw Error.typeMismatch(
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
                throw Error.typeMismatch(
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
    
    open func value(for property: Property, instance: Reflectable) throws -> Any? {
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
