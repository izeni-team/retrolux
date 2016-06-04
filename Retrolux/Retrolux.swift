//
//  Retrolux.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 6/1/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

indirect enum PropertyType: CustomStringConvertible {
    case AnyObject
    case Optional(wrapped: PropertyType)
    case Bool
    case Number
    case String
    case Date
    case Object(type: RetroSerializable.Type)
    case Array(type: PropertyType)
    case Dictionary(type: PropertyType)
    
    func isCompatibleWith(value: Swift.AnyObject) -> Swift.Bool {
        switch self {
        case .AnyObject:
            return true
        case .Optional(let wrapped):
            return value is NSNull || wrapped.isCompatibleWith(value)
        case .Bool:
            return value is NSNumber
        case .Number:
            return value is RetroTypeNumber
        case .String:
            return value is RetroTypeString
        case .Date:
            return value is RetroTypeString
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
    
    var isDate: Swift.Bool {
        switch self {
        case .Date:
            return true
        default:
            return false
        }
    }
    
    var description: Swift.String {
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

protocol RetroSerializable: class {
    // Read/write properties
    func respondsToSelector(selector: Selector) -> Bool // To check if property can be bridged to Obj-C
    func setValue(value: AnyObject?, forKey: String)
    func valueForKey(key: String) -> AnyObject?
    
    // To/from dictionary
    init() // Required in order to provide default implementation for init(json:)
    init(dictionary: [String: AnyObject]) throws
    func toDictionary() -> [String: AnyObject]
    
    // TODO:
    //func copy() -> Self // Lower priority--this is primarily for copying/detaching database models
    //func changes() -> [String: AnyObject]
    //var hasChanges: Bool { get }
    //func resetChanges()
    
    func validate() -> ErrorMessage? // Returns an error
    static var ignoredProperties: [String] { get }
    static var optionalProperties: [String] { get }
    static var mappedProperties: [String: String] { get }
}

struct Property {
    let type: PropertyType
    let name: String
    let required: Bool
    let jsonKey: String
}

var cache: [ObjectIdentifier: [Property]] = [:]

func getObjectType(from object: RetroSerializable, property: String) -> RetroSerializable? {
    return nil
}

func getProperties(fromType type: RetroSerializable.Type) throws -> [Property] {
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

protocol RetroTypeArray {
    static func type() -> PropertyType?
}

protocol RetroTypeDictionary {
    static func type() -> PropertyType?
}

extension Dictionary: RetroTypeDictionary {
    static func type() -> PropertyType? {
        assert(String.self is Key.Type, "Dictionaries must have strings as keys")
        return getPropertyType(Value)
    }
}

protocol RetroTypeNumber {}
extension Int: RetroTypeNumber {}
extension Int8: RetroTypeNumber {}
extension Int16: RetroTypeNumber {}
extension Int32: RetroTypeNumber {}
extension Int64: RetroTypeNumber {}
extension UInt: RetroTypeNumber {}
extension UInt8: RetroTypeNumber {}
extension UInt16: RetroTypeNumber {}
extension UInt32: RetroTypeNumber {}
extension UInt64: RetroTypeNumber {}
extension Float: RetroTypeNumber {}
extension Float64: RetroTypeNumber {}
extension Float80: RetroTypeNumber {}
extension NSNumber: RetroTypeNumber {}
protocol RetroTypeString {}
extension String: RetroTypeString {}
extension NSString: RetroTypeString {}
protocol RetroTypeOptional {
    static func type() -> PropertyType?
}

extension Optional: RetroTypeOptional {
    static func type() -> PropertyType? {
        return getPropertyType(Wrapped)
    }
}

func getPropertyType(type: Any.Type) -> PropertyType? {
    if type == Bool.self {
        return .Bool
    } else if type == AnyObject.self {
        return .AnyObject
    } else if type is RetroTypeString.Type {
        return .String
    } else if type is RetroTypeNumber.Type {
        return .Number
    } else if type == NSDate.self {
        return .Date
    } else if let arr = type as? RetroTypeArray.Type, innerType = arr.type() {
        return .Array(type: innerType)
    } else if let t = type as? RetroSerializable.Type {
        return .Object(type: t)
    } else if let opt = type as? RetroTypeOptional.Type, wrapped = opt.type() {
        return .Optional(wrapped: wrapped)
    } else if let dict = type as? RetroTypeDictionary.Type, innerType = dict.type() {
        return .Dictionary(type: innerType)
    }
    return nil
}

func serializationProperties(forInstance instance: RetroSerializable) throws -> [Property] {
    let ignored = Set(instance.dynamicType.ignoredProperties)
    let optional = Set(instance.dynamicType.optionalProperties)
    let mapped = instance.dynamicType.mappedProperties
    
    // Purposefully ignores labels that are nil
    var properties = [Property]()
    let mirrors: [(label: String, type: Any.Type)] = Mirror(reflecting: instance).children.flatMap({
        guard let label = $0.label else {
            return nil
        }
        return (label: label, type: $0.value.dynamicType)
    })
    let propertyNameSet: Set<String> = Set(mirrors.map({ $0.label }))
    
    if let ignoredButNotImplemented = ignored.subtract(propertyNameSet).first {
        throw RetroluxException.DeserializationError(message: "Cannot ignore non-existent " +
            "property \"\(ignoredButNotImplemented)\" on class \(instance.dynamicType)).")
    }
    if let optionalButNotImplemented = ignored.subtract(propertyNameSet).first {
        throw RetroluxException.DeserializationError(message: "Cannot make non-existent " +
            "property \"\(optionalButNotImplemented)\" optional on class \(instance.dynamicType)).")
    }
    if let ignoredAndOptional = ignored.intersect(optional).first {
        throw RetroluxException.DeserializationError(message: "Cannot make property " +
        "\"\(ignoredAndOptional)\" on class \(instance.dynamicType) both ignored and optional.")
    }
    if let mappedButNotImplemented = Set(mapped.keys).subtract(propertyNameSet).first {
        throw RetroluxException.DeserializationError(message: "Cannot map non-existent " +
            "property \"\(mappedButNotImplemented)\" on class \(instance.dynamicType)).")
    }
    
    for (label, valueType) in mirrors {
        guard !ignored.contains(label) else {
            continue
        }
        guard let type = getPropertyType(valueType) else {
            // TODO: List supported types in error.
            throw RetroluxException.DeserializationError(message: "Unsupported type " +
                "\"\(valueType)\" for property \"\(label)\" on class \(instance.dynamicType).")
        }
        
        guard instance.respondsToSelector(Selector(label)) else {
            switch type {
            case .Optional(let wrapped):
                switch wrapped {
                case .Number:
                    throw RetroluxException.DeserializationError(message: "Property \"\(label)\" on class " +
                        "\(instance.dynamicType) cannot be an optional. Please make it non-optional or use an " +
                        "NSNumber instead.")
                default:
                    break
                }
            default:
                break
            }
            throw RetroluxException.DeserializationError(message: "Property \"\(label)\" on class " +
                "\(instance.dynamicType) has an unsupported type, \(type). Make sure it can be bridged to " +
                "Objective-C by adding the \"dynamic\" keyword in front, or just add it to the list of ignored " +
                "properties.")
        }
        guard !isReadOnly(property: label, instance: instance) else {
            throw RetroluxException.DeserializationError(message: "Property \"\(label)\" on class " +
                "\(instance.dynamicType) is read only. Please make it mutable or add it " +
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

func isReadOnly(property property: String, instance: RetroSerializable) -> Bool {
    let objc_property = class_getProperty(instance.dynamicType, property)
    let c_attributes = property_getAttributes(objc_property)
    let attributes = String(CString: c_attributes, encoding: NSUTF8StringEncoding)!
    return attributes.componentsSeparatedByString(",").contains("R")
}

extension Array: RetroTypeArray {
    static func type() -> PropertyType? {
        return getPropertyType(Element)
    }
}

enum RetroluxException: ErrorType {
    case DeserializationError(message: String)
}

var dateFormatters: [NSDateFormatter] = {
    let locale = NSLocale(localeIdentifier: "en_US_posix")
    
    let f1 = NSDateFormatter()
    f1.locale = locale
    f1.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
    
    let f2 = NSDateFormatter()
    f2.locale = locale
    f2.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
    
    let f3 = NSDateFormatter()
    f3.locale = locale
    f3.dateFormat = "yyyy-MM-dd"
    
    return [f1, f2, f3]
}()

func transform(value: AnyObject, type: PropertyType) throws -> AnyObject {
    switch type {
    case .Optional(let wrapped):
        return try transform(value, type: wrapped)
    case .Array(let elementType):
        guard var array = value as? [AnyObject] else {
            throw RetroluxException.DeserializationError(message: "Expected type Array, but got \(value.dynamicType)")
        }
        for (index, element) in array.enumerate() {
            let transformed = try transform(element, type: elementType)
            if transformed !== element {
                array[index] = transformed
            }
        }
        return array
    case .Dictionary(let valueType):
        guard var dictionary = value as? [String: AnyObject] else {
            throw RetroluxException.DeserializationError(message: "Expected type Dictionary, but got " +
                "\(value.dynamicType)")
        }
        for (key, value) in dictionary {
            let transformed = try transform(value, type: valueType)
            if transformed !== value {
                dictionary[key] = transformed
            }
        }
        return dictionary
    case .Date:
        guard let string = value as? String else {
            throw RetroluxException.DeserializationError(message: "Expected type String, but got \(value.dynamicType)")
        }
        for formatter in dateFormatters {
            if let date = formatter.dateFromString(string) {
                return date
            }
        }
        throw RetroluxException.DeserializationError(message: "Failed to parse date string \"\(value)\"")
    case .Object(let type):
        guard let dictionary = value as? [String: AnyObject] else {
            throw RetroluxException.DeserializationError(message: "Expected type Dictionary, but got " +
                "\(value.dynamicType)")
        }
        return try type.init(dictionary: dictionary)
    case .Bool:
        guard let number = value as? NSNumber else {
            throw RetroluxException.DeserializationError(message: "Expected type Number, but got \(value.dynamicType)")
        }
        guard number.objCType == NSNumber(bool: false).objCType || number.intValue == 0 || number.intValue == 1 else {
            throw RetroluxException.DeserializationError(message: "Expected a boolean, but got a number.")
        }
        return value
    default:
        return value
    }
}

typealias ErrorMessage = String

extension RetroSerializable {
    init(dictionary: [String: AnyObject]) throws {
        self.init()
        do {
            try setProperties(dictionary)
        } catch RetroluxException.DeserializationError(let message) {
            throw RetroluxException.DeserializationError(message: message)
        } catch let error {
            throw error
        }
    }
    
    func setProperties(dictionary: [String: AnyObject]) throws {
        for property in try getProperties(fromType: self.dynamicType) {
            var value: AnyObject! = dictionary[property.jsonKey]
            guard value != nil else {
                guard property.required else {
                    continue
                }
                throw RetroluxException.DeserializationError(message: "Missing key \"\(property.name)\" in json for " +
                    "property \"\(property.name)\" on class \(self.dynamicType).")
            }
            
            guard property.type.isCompatibleWith(value) else {
                guard property.required else {
                    continue
                }
                throw RetroluxException.DeserializationError(message: "Value " +
                    "\(value) is not compatible with type \(property.type) for property " +
                    "\"\(property.name)\" on class \(self.dynamicType).")
            }
            
            if !(value is NSNull) {
                do {
                    value = try transform(value, type: property.type)
                } catch RetroluxException.DeserializationError(let message) {
                    guard property.required else {
                        continue
                    }
                    throw RetroluxException.DeserializationError(message: "Failed to convert value for property " +
                        "\"\(property.name)\" on class \(self.dynamicType) to a \(property.type): \(message)")
                }
            }
            
            setValue(value is NSNull ? nil : value, forKey: property.name)
        }
        
        if let error = validate() {
            throw RetroluxException.DeserializationError(message: "Object \(self) failed validation: \(error)")
        }
    }
    
    func toDictionary() -> [String: AnyObject] {
        return [:]
    }
    
    func validate() -> ErrorMessage? {
        return nil
    }
    
    static var ignoredProperties: [String] {
        return []
    }
    
    static var optionalProperties: [String] {
        return []
    }
    
    static var mappedProperties: [String: String] {
        return [:]
    }
}

class Person: NSObject, RetroSerializable {
    required override init() {
        super.init()
    }
    
    var name: String = ""
    var friend: Person?
    
    static let optionalProperties = ["name", "friend"]
    
    override var description: String {
        if let f = friend {
            return "Person{name: \(name), friend: \(f)}"
        } else {
            return "Person{name: \(name)}"
        }
    }
}

class Model: NSObject, RetroSerializable {
    required override init() {
        super.init()
    }
    
    var string = "(default value)"
    var string_opt: String? = "(default value)"
    var failure_string: String = "(default value)"
    var int = 0
    var float = 0.0
    var number_opt: NSNumber?
    var list_anyobject: [AnyObject]? = []
    var strings_2d: [[AnyObject]] = []
    var date: NSDate?
    var dates: [NSDate] = []
    var date_dict: [String: NSDate] = [:]
    var date_dict_array: [String: [[String: NSDate]]] = [:]
    var craycray: [String: [String: [String: [Int]]]] = [:]
    var person: Person?
    var friends: [Person] = []
    
    var thing_number: NSNumber?
    var thing_string: String?
    
    var notSerializable: Bool? = nil
    
    static let ignoredProperties = ["notSerializable"]
    static let optionalProperties = ["failure_string", "thing_number", "thing_string"]
    static let mappedProperties = [
        "thing_number": "thing",
        "thing_string": "thing"
    ]

    func validate() -> ErrorMessage? {
        if thing_number == nil && thing_string == nil {
            return "missing thing"
        }
        return nil
    }
    
    override var description: String {
        return "Model {\n" +
            "  string: \(string)\n" +
            "  string_opt: \(string_opt)\n" +
            "  failure_string: \(failure_string)\n" +
            "  int: \(int)\n" +
            "  float: \(float)\n" +
            "  number_opt: \(number_opt)\n" +
            "  list_anyobject: \(list_anyobject)\n" +
            "  strings_2d: \(strings_2d)\n" +
            "  date: \(date)\n" +
            "  dates: \(dates)\n" +
            "  date_dict: \(date_dict)\n" +
            "  date_dict_array: \(date_dict_array)\n" +
            "  craycray: \(craycray)\n" +
            "  person: \(person)\n" +
            "  friends: \(friends)\n" +
            "  thing_number: \(thing_number)\n" +
            "  thing_string: \(thing_string)\n" +
        "}"
    }
}