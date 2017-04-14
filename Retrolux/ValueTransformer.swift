//
//  ValueTransformer.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 10/16/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

public enum ValueTransformerDirection {
    case forwards
    case backwards
}

public enum ValueTransformationError: Error {
    case typeMismatch(got: Any.Type?)
}

// If property is like:
//     var friend: Person?
// then targetType will be Person.self.
//
// If property is like:
//     var friend: [Person] = []
// then targetType will still be Person.self.
public protocol ValueTransformer {
    func supports(targetType: Any.Type) -> Bool
    func transform(_ value: Any, targetType: Any.Type, direction: ValueTransformerDirection) throws -> Any
}

internal func reflectable_transform(value: Any, propertyName: String, classType: Any.Type, type: PropertyType, transformer: TransformerType, direction: TransformerDirection) throws -> Any {
    return value
//    switch type {
//    case .anyObject:
//        return value
//    case .optional(let wrapped):
//        return try reflectable_transform(
//            value: value,
//            propertyName: propertyName,
//            classType: classType,
//            type: wrapped,
//            transformer: transformer,
//            direction: direction
//        )
//    case .bool:
//        return value
//    case .number:
//        return value
//    case .string:
//        return value
//    case .transformable(transformer: let transformer, targetType: let targetType):
//        return try transformer.transform(value, targetType: targetType, direction: direction)
//    case .array(let element):
//        guard let array = value as? [Any] else {
//            throw ValueTransformationError.typeMismatch(got: type(of: value))
//        }
//        return try array.map {
//            try reflectable_transform(
//                value: $0,
//                propertyName: propertyName,
//                classType: classType,
//                type: element,
//                transformer: transformer,
//                direction: direction
//            )
//        }
//    case .dictionary(let valueType):
//        guard let dictionary = value as? [String: Any] else {
//            // TODO: Add a test for this.
//            throw ReflectorSerializationError.typeMismatch(expected: type, got: type(of: value), propertyName: propertyName, forClass: classType)
//        }
//        var result: [String: Any] = [:]
//        for (key, value) in dictionary {
//            result[key] = try reflectable_transform(
//                value: value,
//                propertyName: propertyName,
//                classType: classType,
//                type: valueType,
//                transformer: transformer,
//                direction: direction
//            )
//        }
//        return result
//    }
}
