//
//  PropertyType.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 7/12/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

private protocol RLArrayType {
    static func rl_type() -> Any.Type
}

extension Array: RLArrayType {
    fileprivate static func rl_type() -> Any.Type {
        return Element.self
    }
}

extension NSArray: RLArrayType {
    fileprivate static func rl_type() -> Any.Type {
        return AnyObject.self
    }
}

private protocol RLDictionaryType {
    static func rl_type() -> Any.Type
}    

extension Dictionary: RLDictionaryType {
    fileprivate static func rl_type() -> Any.Type {
        assert(String.self is Key.Type, "Dictionaries must have strings as keys")
        return Value.self
    }
}

extension NSDictionary: RLDictionaryType {
    fileprivate static func rl_type() -> Any.Type {
        return AnyObject.self
    }
}

fileprivate protocol RLOptionalType {
    static func rl_type() -> Any.Type
}

extension Optional: RLOptionalType {
    fileprivate static func rl_type() -> Any.Type {
        return Wrapped.self
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
    case any
    case anyObject
    case optional(PropertyType)
    case bool
    case number(Any.Type)
    case string
    case array(PropertyType)
    case dictionary(PropertyType)
    case unknown(Any.Type)
    
    public static func from(_ type: Any.Type) -> PropertyType {
        if type == Bool.self {
            return .bool
        } else if type == AnyObject.self {
            return .anyObject
        } else if type == Any.self {
            return .any
        } else if type is RLStringType.Type {
            return .string
        } else if type is RLNumberType.Type {
            return .number(type)
        } else if let arr = type as? RLArrayType.Type {
            return .array(from(arr.rl_type()))
        } else if let opt = type as? RLOptionalType.Type {
            return .optional(from(opt.rl_type()))
        } else if let dict = type as? RLDictionaryType.Type {
            return .dictionary(from(dict.rl_type()))
        } else {
            return .unknown(type)
        }
    }
    
    public var bottom: PropertyType {
        switch self {
        case .any, .anyObject, .bool, .string, .unknown, .number:
            return self
        case .array(let inner):
            return inner.bottom
        case .dictionary(let inner):
            return inner.bottom
        case .optional(let wrapped):
            return wrapped.bottom
        }
    }
    
    public func isCompatible(with value: Any?, transformer: TransformerType?) -> Bool {
        if transformer?.supports(propertyType: self) == true {
            return true
        }
        
        switch self {
        case .any, .anyObject:
            return true
        case .optional(let wrapped):
            return value is NSNull || value == nil || wrapped.isCompatible(with: value, transformer: transformer)
        case .bool:
            return value is NSNumber
        case .number:
            return value is RLNumberType
        case .string:
            return value is RLStringType
        case .unknown:
            // There is no pre-assignment validation for transformables.
            // Validation will have to be done during actual assignment.
            return true
        case .array(let element):
            guard let array = value as? [AnyObject] else {
                return false
            }
            return !array.contains {
                !element.isCompatible(with: $0, transformer: transformer)
            }
        case .dictionary(let valueType):
            guard let dictionary = value as? [String : AnyObject] else {
                return false
            }
            return !dictionary.values.contains {
                !valueType.isCompatible(with: $0, transformer: transformer)
            }
        }
    }
    
    public var description: String {
        switch self {
        case .any: return "any"
        case .anyObject: return "anyObject"
        case .dictionary(let innerType): return "dictionary<\(innerType)>"
        case .array(let innerType): return "array<\(innerType)>"
        case .bool: return "bool"
        case .number: return "number"
        case .unknown(let type): return "unknown(\(type))"
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
    case .any:
        if case .any = rhs {
            return true
        }
    case .anyObject:
        if case .anyObject = rhs {
            return true
        }
    case .array(let innerType):
        if case .array(let innerType2) = rhs {
            return innerType == innerType2
        }
    case .bool:
        if case .bool = rhs {
            return true
        }
    case .dictionary(let innerType):
        if case .dictionary(let innerType2) = rhs {
            return innerType == innerType2
        }
    case .number(let exactType):
        if case .number(let otherExactType) = rhs {
            return exactType == otherExactType
        }
    case .unknown(let type):
        if case .unknown(let otherType) = rhs {
            return type == otherType
        }
    case .optional(let wrapped):
        if case .optional(let wrapped2) = rhs {
            return wrapped == wrapped2
        }
    case .string:
        if case .string = rhs {
            return true
        }
    }
    return false
}
