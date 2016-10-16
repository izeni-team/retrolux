//
//  PropertyType.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 7/12/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

private protocol RLArrayType {
    static func type() -> PropertyType?
}

extension Array: RLArrayType {
    fileprivate static func type() -> PropertyType? {
        return PropertyType.from(Element.self)
    }
}

extension NSArray: RLArrayType {
    fileprivate static func type() -> PropertyType? {
        return .anyObject
    }
}

private protocol RLDictionaryType {
    static func type() -> PropertyType?
}    

extension Dictionary: RLDictionaryType {
    fileprivate static func type() -> PropertyType? {
        assert(String.self is Key.Type, "Dictionaries must have strings as keys")
        return PropertyType.from(Value.self)
    }
}

extension NSDictionary: RLDictionaryType {
    fileprivate static func type() -> PropertyType? {
        return .anyObject
    }
}

private protocol RLOptionalType {
    static func type() -> PropertyType?
}

extension Optional: RLOptionalType {
    fileprivate static func type() -> PropertyType? {
        return PropertyType.from(Wrapped.self)
    }
}

private protocol RLStringType {}
extension String: RLStringType {}
extension NSString: RLStringType {}

private protocol RLNumberType {}
extension Int: RLNumberType {}
extension Int8: RLNumberType {}
extension Int16: RLNumberType {}
extension Int32: RLNumberType {}
extension Int64: RLNumberType {}
extension UInt: RLNumberType {}
extension UInt8: RLNumberType {}
extension UInt16: RLNumberType {}
extension UInt32: RLNumberType {}
extension UInt64: RLNumberType {}
extension Float: RLNumberType {}
extension Float64: RLNumberType {}
extension NSNumber: RLNumberType {}

public enum PropertyValueTransformerDirection {
    case forwards
    case backwards
}

public protocol PropertyValueTransformer {
    func supports(type: Any.Type, direction: PropertyValueTransformerDirection) -> Bool
    
    // TODO: Rename to validate.
    func supports(value: Any, direction: PropertyValueTransformerDirection) -> Bool
    
    func transform(_ value: Any, direction: PropertyValueTransformerDirection) throws -> Any
}

public indirect enum PropertyType: CustomStringConvertible, Equatable {
    case anyObject
    case optional(wrapped: PropertyType)
    case bool
    case number
    case string
    case array(type: PropertyType)
    case dictionary(type: PropertyType)
    case transformable(transformer: PropertyValueTransformer)
    
    // TODO: How to make this a custom initializer instead of a static function?
    public static func from(_ type: Any.Type) -> PropertyType? {
        var transformerMatched = false
        return from(type, transformer: nil, transformerMatched: &transformerMatched)
    }
    
    public static func from(_ type: Any.Type, transformer: PropertyValueTransformer?, transformerMatched: inout Bool) -> PropertyType? {
        if let transformer = transformer, transformer.supports(type: type, direction: .forwards) {
            transformerMatched = true
            return PropertyType.transformable(transformer: transformer)
        } else if type == Bool.self {
            return PropertyType.bool
        } else if type == AnyObject.self {
            return .anyObject
        } else if type is RLStringType.Type {
            return PropertyType.string
        } else if type is RLNumberType.Type {
            return PropertyType.number
        } else if let arr = type as? RLArrayType.Type, let innerType = arr.type() {
            return PropertyType.array(type: innerType)
        } else if let opt = type as? RLOptionalType.Type, let wrapped = opt.type() {
            return PropertyType.optional(wrapped: wrapped)
        } else if let dict = type as? RLDictionaryType.Type, let innerType = dict.type() {
            return PropertyType.dictionary(type: innerType)
        } else {
            return nil
        }
    }
    
    public func isCompatible(with value: Any?) -> Bool {
        switch self {
        case .anyObject:
            return true
        case .optional(let wrapped):
            return value is NSNull || value == nil || wrapped.isCompatible(with: value)
        case .bool:
            return value is NSNumber
        case .number:
            return value is RLNumberType
        case .string:
            return value is RLStringType
        case .transformable(let transformer):
            return transformer.supports(value: value, direction: .forwards)
        case .array(let element):
            guard let array = value as? [AnyObject] else {
                return false
            }
            return !array.contains {
                !element.isCompatible(with: $0)
            }
        case .dictionary(let valueType):
            guard let dictionary = value as? [String : AnyObject] else {
                return false
            }
            return !dictionary.values.contains {
                !valueType.isCompatible(with: $0)
            }
        }
    }
    
    public var description: String {
        switch self {
        case .anyObject: return "anyObject"
        case .dictionary(let innerType): return "dictionary<\(innerType)>"
        case .array(let innerType): return "array<\(innerType)>"
        case .bool: return "bool"
        case .number: return "number"
        case .transformable(let transformer): return "\(transformer)"
        case .optional(let wrapped): return "optional<\(wrapped)>"
        case .string: return "string"
        }
    }
}

/*
 Intended for unit testing, but hey, if you find it useful, power to you!
 */
public func ==(lhs: PropertyType, rhs: PropertyType) -> Bool {
    switch lhs {
    case .anyObject:
        if case PropertyType.anyObject = rhs {
            return true
        }
    case .array(let innerType):
        if case PropertyType.array(let innerType2) = rhs {
            return innerType == innerType2
        }
    case .bool:
        if case PropertyType.bool = rhs {
            return true
        }
    case .dictionary(let innerType):
        if case PropertyType.dictionary(let innerType2) = rhs {
            return innerType == innerType2
        }
    case .number:
        if case PropertyType.number = rhs {
            return true
        }
    case .transformable(let transformer):
        if case PropertyType.transformable(let transformer2) = rhs {
            // Only return true if the same transformer type is being used.
            // I.e., if classes are the same--not necessarily the same instance.
            return type(of: transformer) == type(of: transformer2)
        }
    case .optional(let wrapped):
        if case PropertyType.optional(let wrapped2) = rhs {
            return wrapped == wrapped2
        }
    case .string:
        if case PropertyType.string = rhs {
            return true
        }
    }
    return false
}
