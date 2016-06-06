//
//  Retrolux.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 6/1/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

public typealias ErrorMessage = String

public protocol NetworkResponseConvertible {
    static func fromNetworkResponse(object: AnyObject) throws -> Any
}

public protocol Serializable: NSObjectProtocol, NetworkResponseConvertible {
    // Read/write properties
    func respondsToSelector(selector: Selector) -> Bool // To check if property can be bridged to Obj-C
    func setValue(value: AnyObject?, forKey: String) // For JSON -> Object deserialization
    func valueForKey(key: String) -> AnyObject? // For Object -> JSON serialization
    
    // To/from dictionary
    init() // Required in order to provide default implementation for init(json:)
    init(dictionary: [String: AnyObject]) throws
    func toDictionary() throws -> [String: AnyObject]
    func toJSONData() throws -> NSData
    func toJSONString() throws -> String
    
    // TODO:
    //func copy() -> Self // Lower priority--this is primarily for copying/detaching database models
    //func changes() -> [String: AnyObject]
    //var hasChanges: Bool { get }
    //func clearChanges() resetChanges() markAsHavingNoChanges() What to name this thing?
    //func revertChanges() // MAYBE?
    
    func validate() -> ErrorMessage?
    static var ignoredProperties: [String] { get }
    static var optionalProperties: [String] { get }
    static var mappedProperties: [String: String] { get }
}

extension Serializable {
    public init(dictionary: [String: AnyObject]) throws {
        self.init()
        try Retrolux.serializer.setPropertiesFor(instance: self, fromDictionary: dictionary)
    }
    
    public func toDictionary() throws -> [String: AnyObject] {
        return try Retrolux.serializer.serializeToDictionary(self)
    }
    
    public func toJSONData() throws -> NSData {
        return try Retrolux.serializer.serializeToJSONData(self)
    }
    
    public func toJSONString() throws -> String {
        return try Retrolux.serializer.serializeToJSONString(self)
    }
    
    public func validate() -> ErrorMessage? {
        return nil
    }
    
    public static var ignoredProperties: [String] {
        return []
    }
    
    public static var optionalProperties: [String] {
        return []
    }
    
    public static var mappedProperties: [String: String] {
        return [:]
    }
    
    public static func fromNetworkResponse(object: AnyObject) throws -> Any {
        guard let dictionary = object as? [String: AnyObject] else {
            throw RetroluxException.SerializerError(message: "Cannot convert response of type \(object.dynamicType) into a \(self.dynamicType).")
        }
        return try self.init(dictionary: dictionary)
    }
}

public class RetroluxObject: NSObject, Serializable {
    public required override init() {
        super.init()
    }
    
    public required convenience init(dictionary: [String: AnyObject]) throws {
        self.init()
        try Retrolux.serializer.setPropertiesFor(instance: self, fromDictionary: dictionary)
    }
    
    public func toDictionary() throws -> [String: AnyObject] {
        return try Retrolux.serializer.serializeToDictionary(self)
    }
    
    public func toJSONData() throws -> NSData {
        return try Retrolux.serializer.serializeToJSONData(self)
    }
    
    public func toJSONString() throws -> String {
        return try Retrolux.serializer.serializeToJSONString(self)
    }
    
    public func validate() -> ErrorMessage? {
        return nil
    }
    
    public class var ignoredProperties: [String] {
        return []
    }
    
    public class var optionalProperties: [String] {
        return []
    }
    
    public class var mappedProperties: [String: String] {
        return [:]
    }
}

public class Serializer {
    public enum TransformDirection {
        case ToJSON
        case FromJSON
    }
    
    public static let sharedInstance = Serializer()
    
    public var dateFormatters: [NSDateFormatter] = {
        let locale = NSLocale(localeIdentifier: "en_US_posix")
        
        let f1 = NSDateFormatter()
        f1.locale = locale
        f1.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        
        let f2 = NSDateFormatter()
        f2.locale = locale
        f2.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        
        return [f1, f2]
    }()
    
    public indirect enum PropertyType: CustomStringConvertible {
        case AnyObject
        case Optional(wrapped: PropertyType)
        case Bool
        case Number
        case String
        case Date
        case Object(type: Serializable.Type)
        case Array(type: PropertyType)
        case Dictionary(type: PropertyType)
        
        public func isCompatibleWith(value: Swift.AnyObject) -> Swift.Bool {
            switch self {
            case .AnyObject:
                return true
            case .Optional(let wrapped):
                return value is NSNull || wrapped.isCompatibleWith(value)
            case .Bool:
                return value is NSNumber
            case .Number:
                return value is SerializerNumberType
            case .String:
                return value is SerializerStringType
            case .Date:
                return value is SerializerStringType
            case .Object:
                return value is NSDictionary
            case .Array(let element):
                if let array = value as? [Swift.AnyObject] {
                    for innerValue in array {
                        if !element.isCompatibleWith(innerValue) {
                            return false
                        }
                    }
                    return true
                }
                return false
            case .Dictionary(let valueType):
                if let dictionary = value as? [Swift.String: Swift.AnyObject] {
                    for innerValue in dictionary.values {
                        if !valueType.isCompatibleWith(innerValue) {
                            return false
                        }
                    }
                    return true
                }
                return false
            }
        }
        
        public var isDate: Swift.Bool {
            switch self {
            case .Date:
                return true
            default:
                return false
            }
        }
        
        public var description: Swift.String {
            switch self {
            case .AnyObject: return "AnyObject"
            case .Date: return "Date"
            case .Dictionary(let innerType): return "Dictionary<\(innerType)>"
            case .Array(let innerType): return "Array<\(innerType)>"
            case .Bool: return "Bool"
            case .Number: return "Number"
            case .Object(let type): return "\(type)"
            case .Optional(let wrapped): return "Optional<\(wrapped)>"
            case .String: return "String"
            }
        }
    }
    
    public struct Property {
        public let type: PropertyType
        public let name: String
        public let required: Bool
        public let jsonKey: String
    }
    
    public var cache: [ObjectIdentifier: [Property]] = [:]
    
    public func getObjectType(from object: Serializable, property: String) -> Serializable? {
        return nil
    }
    
    public func getProperties(fromType type: Serializable.Type) throws -> [Property] {
        let identifier = ObjectIdentifier(type)
        if let properties = cache[identifier] {
            // Cached already
            return properties
        }
        
        // Add to cache
        let properties = try serializationProperties(forInstance: type.init())
        cache[identifier] = properties
        return properties
    }
    
    public func getPropertyType(type: Any.Type) -> PropertyType? {
        if type == Bool.self {
            return .Bool
        } else if type == AnyObject.self {
            return .AnyObject
        } else if type is SerializerStringType.Type {
            return .String
        } else if type is SerializerNumberType.Type {
            return .Number
        } else if type == NSDate.self {
            return .Date
        } else if let arr = type as? SerializerArrayType.Type, innerType = arr.type() {
            return .Array(type: innerType)
        } else if let t = type as? Serializable.Type {
            return .Object(type: t)
        } else if let opt = type as? SerializerOptionalType.Type, wrapped = opt.type() {
            return .Optional(wrapped: wrapped)
        } else if let dict = type as? SerializerDictionaryType.Type, innerType = dict.type() {
            return .Dictionary(type: innerType)
        }
        return nil
    }
    
    public func getMirrorChildren(mirror: Mirror, parentMirror: Mirror?) throws -> [(label: String, valueType: Any.Type)] {
        var children = [(label: String, valueType: Any.Type)]()
        if let superMirror = mirror.superclassMirror() where superMirror.subjectType is Serializable.Type {
            children = try getMirrorChildren(superMirror, parentMirror: mirror)
        } else if let parent = parentMirror
            where parent.subjectType is Serializable.Type && mirror.subjectType != RetroluxObject.self {
            throw RetroluxException.SerializerError(message: "Subclassing is not supported unless the base " +
                "class is \(RetroluxObject.self).")
        }
        
        // Purposefully ignores labels that are nil
        return children + mirror.children.flatMap {
            guard let label = $0.label else {
                return nil
            }
            return (label, $0.value.dynamicType)
        }
    }
    
    public func serializationProperties(forInstance instance: Serializable) throws -> [Property] {
        var properties = [Property]()
        let subjectType = instance.dynamicType
        
        let ignored = Set(subjectType.ignoredProperties)
        let optional = Set(subjectType.optionalProperties)
        let mapped = subjectType.mappedProperties
        
        let children = try getMirrorChildren(Mirror(reflecting: instance), parentMirror: nil)
        let propertyNameSet: Set<String> = Set(children.map({ $0.label }))
        
        if let ignoredButNotImplemented = ignored.subtract(propertyNameSet).first {
            throw RetroluxException.SerializerError(message: "Cannot ignore non-existent " +
                "property \"\(ignoredButNotImplemented)\" on class \(subjectType).")
        }
        if let optionalButNotImplemented = optional.subtract(propertyNameSet).first {
            throw RetroluxException.SerializerError(message: "Cannot make non-existent " +
                "property \"\(optionalButNotImplemented)\" optional on class \(subjectType).")
        }
        if let ignoredAndOptional = ignored.intersect(optional).first {
            throw RetroluxException.SerializerError(message: "Cannot make property " +
                "\"\(ignoredAndOptional)\" on class \(subjectType) both ignored and optional.")
        }
        if let mappedButNotImplemented = Set(mapped.keys).subtract(propertyNameSet).first {
            throw RetroluxException.SerializerError(message: "Cannot map non-existent " +
                "property \"\(mappedButNotImplemented)\" on class \(subjectType).")
        }
        let excessivelyMapped = mapped.filter { k1, v1 in mapped.contains { v1 == $1 && k1 != $0 } }
        if !excessivelyMapped.isEmpty {
            let pickOne = excessivelyMapped.first!.1
            let propertiesForIt = excessivelyMapped.filter { $1 == pickOne }.map { $0.0 }
            throw RetroluxException.SerializerError(message: "Cannot map multiple properties, " +
                "\(propertiesForIt), on class \(subjectType) to the same key, \"\(pickOne)\".")
        }
        
        for (label, valueType) in children {
            guard !ignored.contains(label) else {
                continue
            }
            guard let type = getPropertyType(valueType) else {
                // TODO: List supported types in error.
                throw RetroluxException.SerializerError(message: "Unsupported type " +
                    "\"\(valueType)\" for property \"\(label)\" on class \(subjectType).")
            }
            
            guard instance.respondsToSelector(Selector(label)) else {
                switch type {
                case .Optional(let wrapped):
                    switch wrapped {
                    case .Number:
                        throw RetroluxException.SerializerError(message: "Property \"\(label)\" on class " +
                            "\(subjectType) cannot be an optional. Please make it non-optional or use an " +
                            "NSNumber instead.")
                    default:
                        break
                    }
                default:
                    break
                }
                throw RetroluxException.SerializerError(message: "Property \"\(label)\" on class " +
                    "\(subjectType) has an unsupported type, \(type). Make sure it can be bridged to " +
                    "Objective-C by adding the \"dynamic\" keyword in front, or just add it to the list of ignored " +
                    "properties.")
            }
            guard !isReadOnly(property: label, instance: instance) else {
                throw RetroluxException.SerializerError(message: "Property \"\(label)\" on class " +
                    "\(subjectType) is read only. Please make it mutable or add it " +
                    "as an ignored property.")
            }
            properties.append(Property(
                type: type,
                name: label,
                required: !optional.contains(label),
                jsonKey: mapped[label] ?? label
                ))
        }
        
        return properties
    }
    
    public func isReadOnly(property property: String, instance: Serializable) -> Bool {
        let objc_property = class_getProperty(instance.dynamicType, property)
        let c_attributes = property_getAttributes(objc_property)
        let attributes = String(CString: c_attributes, encoding: NSUTF8StringEncoding)!
        return attributes.componentsSeparatedByString(",").contains("R")
    }
    
    public func transform(value: AnyObject, type: PropertyType, direction: TransformDirection) throws -> AnyObject {
        switch type {
        case .Optional(let wrapped):
            return try transform(value, type: wrapped, direction: direction)
        case .Array(let elementType):
            guard var array = value as? [AnyObject] else {
                throw RetroluxException.SerializerError(message: "Expected type Array, but got \(value.dynamicType)")
            }
            for (index, element) in array.enumerate() {
                let transformed = try transform(element, type: elementType, direction: direction)
                if transformed !== element {
                    array[index] = transformed
                }
            }
            return array
        case .Dictionary(let valueType):
            guard var dictionary = value as? [String: AnyObject] else {
                throw RetroluxException.SerializerError(message: "Expected type Dictionary, but got " +
                    "\(value.dynamicType)")
            }
            for (key, value) in dictionary {
                let transformed = try transform(value, type: valueType, direction: direction)
                if transformed !== value {
                    dictionary[key] = transformed
                }
            }
            return dictionary
        case .Date:
            switch direction {
            case .FromJSON:
                guard let string = value as? String else {
                    throw RetroluxException.SerializerError(message: "Expected type String, but got " +
                        "\(value.dynamicType)")
                }
                for formatter in dateFormatters {
                    if let date = formatter.dateFromString(string) {
                        return date
                    }
                }
                throw RetroluxException.SerializerError(message: "Failed to parse date string \"\(value)\"")
            case .ToJSON:
                if let date = value as? NSDate {
                    return dateFormatters.first!.stringFromDate(date)
                }
                return NSNull()
            }
        case .Object(let type):
            switch direction {
            case .FromJSON:
                guard let dictionary = value as? [String: AnyObject] else {
                    throw RetroluxException.SerializerError(message: "Expected type Dictionary, but got " +
                        "\(value.dynamicType)")
                }
                return try type.init(dictionary: dictionary)
            case .ToJSON:
                guard let object = value as? Serializable else {
                    throw RetroluxException.SerializerError(message: "Expected type \(Serializable.self), but got " +
                        "\(value.dynamicType)")
                }
                return try object.toDictionary()
            }
        case .Bool:
            guard let number = value as? NSNumber else {
                throw RetroluxException.SerializerError(message: "Expected type Number, but got \(value.dynamicType)")
            }
            guard number.objCType == NSNumber(bool: false).objCType ||
                number.intValue == 0 ||
                number.intValue == 1 else {
                throw RetroluxException.SerializerError(message: "Expected a boolean, but got a number.")
            }
            return value
        default:
            return value
        }
    }
    
    public func serializeToDictionary(instance: Serializable) throws -> [String: AnyObject] {
        var output = [String: AnyObject]()
        for property in try getProperties(fromType: instance.dynamicType) {
            if let value = instance.valueForKey(property.name) {
                output[property.jsonKey] = try transform(value, type: property.type, direction: .ToJSON)
            } else {
                output[property.jsonKey] = NSNull()
            }
        }
        return output
    }
    
    public func serializeToJSONData(instance: Serializable) throws -> NSData {
        do {
            let dictionary = try instance.toDictionary()
            return try NSJSONSerialization.dataWithJSONObject(dictionary, options: [])
        } catch RetroluxException.SerializerError(let message) {
            throw RetroluxException.SerializerError(message: "Failed to convert \(instance.dynamicType) to a JSON " +
                "string: \(message)")
        } catch let error as NSError {
            throw RetroluxException.SerializerError(message: "Failed to convert \(instance.dynamicType) to a JSON " +
                "string: \(error.localizedDescription)")
        }
    }
    
    public func serializeToJSONString(instance: Serializable) throws -> String {
        return String(data: try instance.toJSONData(), encoding: NSUTF8StringEncoding)!
    }
    
    public func setPropertiesFor(instance instance: Serializable, fromDictionary dictionary: [String: AnyObject]) throws {
        for property in try getProperties(fromType: instance.dynamicType) {
            var value: AnyObject! = dictionary[property.jsonKey]
            guard value != nil else {
                guard property.required else {
                    continue
                }
                throw RetroluxException.SerializerError(message: "Missing key \"\(property.name)\" in json for " +
                    "property \"\(property.name)\" on class \(instance.dynamicType).")
            }
            
            guard property.type.isCompatibleWith(value) else {
                guard property.required else {
                    continue
                }
                throw RetroluxException.SerializerError(message: "Value " +
                    "\(value) is not compatible with type \(property.type) for property " +
                    "\"\(property.name)\" on class \(instance.dynamicType).")
            }
            
            if !(value is NSNull) {
                do {
                    value = try transform(value, type: property.type, direction: .FromJSON)
                } catch RetroluxException.SerializerError(let message) {
                    guard property.required else {
                        continue
                    }
                    throw RetroluxException.SerializerError(message: "Failed to convert value for property " +
                        "\"\(property.name)\" on class \(instance.dynamicType) to a \(property.type): \(message)")
                }
            }
            
            instance.setValue(value is NSNull ? nil : value, forKey: property.name)
        }
        
        if let error = instance.validate() {
            throw RetroluxException.SerializerError(message: "Object \(instance) failed validation: \(error)")
        }
    }
}

public protocol SerializerArrayType {
    static func type() -> Serializer.PropertyType?
}

extension Array: SerializerArrayType {
    public static func type() -> Serializer.PropertyType? {
        return Retrolux.serializer.getPropertyType(Element)
    }
}

public protocol SerializerDictionaryType {
    static func type() -> Serializer.PropertyType?
}

extension Dictionary: SerializerDictionaryType {
    public static func type() -> Serializer.PropertyType? {
        assert(String.self is Key.Type, "Dictionaries must have strings as keys")
        return Retrolux.serializer.getPropertyType(Value)
    }
}

public protocol SerializerOptionalType {
    static func type() -> Serializer.PropertyType?
}

extension Optional: SerializerOptionalType {
    public static func type() -> Serializer.PropertyType? {
        return Retrolux.serializer.getPropertyType(Wrapped)
    }
}

public protocol SerializerStringType {}
extension String: SerializerStringType {}
extension NSString: SerializerStringType {}

public protocol SerializerNumberType {}
extension Int: SerializerNumberType {}
extension Int8: SerializerNumberType {}
extension Int16: SerializerNumberType {}
extension Int32: SerializerNumberType {}
extension Int64: SerializerNumberType {}
extension UInt: SerializerNumberType {}
extension UInt8: SerializerNumberType {}
extension UInt16: SerializerNumberType {}
extension UInt32: SerializerNumberType {}
extension UInt64: SerializerNumberType {}
extension Float: SerializerNumberType {}
extension Float64: SerializerNumberType {}
extension NSNumber: SerializerNumberType {}
