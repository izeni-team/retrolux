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
        return PropertyType.from(Element)
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
        return PropertyType.from(Value)
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
        return PropertyType.from(Wrapped)
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

public indirect enum PropertyType: CustomStringConvertible, Equatable {
    case anyObject
    case optional(wrapped: PropertyType)
    case bool
    case number
    case string
    case object(type: RLObjectProtocol.Type)
    case array(type: PropertyType)
    case dictionary(type: PropertyType)
    
    // Making a custom init didn't compile, so it's a static func
    public static func from(_ type: Any.Type) -> PropertyType? {
        if type == Bool.self {
            return PropertyType.bool
        } else if type == AnyObject.self {
            return .anyObject
        } else if type is RLStringType.Type {
            return PropertyType.string
        } else if type is RLNumberType.Type {
            return PropertyType.number
        } else if let arr = type as? RLArrayType.Type, let innerType = arr.type() {
            return PropertyType.array(type: innerType)
        } else if let t = type as? RLObjectProtocol.Type {
            return PropertyType.object(type: t)
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
        case .object:
            return value is NSDictionary
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
        case .object(let type): return "\(type)"
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
    case .object(let classType):
        if case PropertyType.object(let classType2) = rhs {
            return classType == classType2
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
