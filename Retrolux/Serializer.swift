////
////  Retrolux.swift
////  Retrolux
////
////  Created by Christopher Bryan Henderson on 6/1/16.
////  Copyright © 2016 Bryan. All rights reserved.
////
//
//import Foundation
//
//public typealias ErrorMessage = String
//
//@available(*, deprecated=1.0, message="Will be removed in v0.1.0")
//public protocol NetworkResponseConvertible {
//    @available(*, deprecated=1.0, message="Will be removed in v0.1.0")
//    static func fromNetworkResponse(object: AnyObject) throws -> Any
//}
//
//public protocol Serializable: NSObjectProtocol, NetworkResponseConvertible {
//    // Read/write properties
//    func respondsToSelector(selector: Selector) -> Bool // To check if property can be bridged to Obj-C
//    func setValue(value: AnyObject?, forKey: String) // For JSON -> Object deserialization
//    func valueForKey(key: String) -> AnyObject? // For Object -> JSON serialization
//    
//    init() // Required in order to provide default implementation for init(json:)
//    
//    // To/from dictionary
//    @available(*, deprecated=1.0, message="Will be removed in v0.1.0")
//    init(dictionary: [String: AnyObject]) throws
//    @available(*, deprecated=1.0, message="Will be removed in v0.1.0")
//    func toDictionary() throws -> [String: AnyObject]
//    @available(*, deprecated=1.0, message="Will be removed in v0.1.0")
//    func toData() throws -> NSData
//    @available(*, deprecated=1.0, message="Will be removed in v0.1.0")
//    func toString() throws -> String
//    
//    // TODO:
//    //func copy() -> Self // Lower priority--this is primarily for copying/detaching database models
//    //func changes() -> [String: AnyObject]
//    //var hasChanges: Bool { get }
//    //func clearChanges() resetChanges() markAsHavingNoChanges() What to name this thing?
//    //func revertChanges() // MAYBE?
//    
//    func validate() -> ErrorMessage?
//    static var ignoredProperties: [String] { get }
//    @available(*, deprecated=1.0, renamed="ignoreErrorsForProperties", message="Will be removed in v0.1.0")
//    static var optionalProperties: [String] { get }
//    static var ignoreErrorsForProperties: [String] { get }
//    static var mappedProperties: [String: String] { get }
//}
//
//extension Serializable {
//    public init(dictionary: [String: AnyObject]) throws {
//        self.init()
//        try Retrolux.serializer.setPropertiesFor(instance: self, fromDictionary: dictionary)
//    }
//    
//    public func toDictionary() throws -> [String: AnyObject] {
//        return try Retrolux.serializer.serializeToDictionary(self)
//    }
//    
//    public func toData() throws -> NSData {
//        return try Retrolux.serializer.serializeToData(self)
//    }
//    
//    public func toString() throws -> String {
//        return try Retrolux.serializer.serializeToString(self)
//    }
//    
//    public func validate() -> ErrorMessage? {
//        return nil
//    }
//    
//    public static var ignoredProperties: [String] {
//        return []
//    }
//    
//    public static var optionalProperties: [String] {
//        return ignoreErrorsForProperties
//    }
//    
//    public static var ignoreErrorsForProperties: [String] {
//        return []
//    }
//    
//    public static var mappedProperties: [String: String] {
//        return [:]
//    }
//    
//    @available(*, deprecated=1.0, message="Will be removed in v0.1.0")
//    public static func fromNetworkResponse(object: AnyObject) throws -> Any {
//        guard let dictionary = object as? [String: AnyObject] else {
//            throw RetroluxException.SerializerError(message: "Cannot convert response of type \(object.dynamicType) into a \(self.dynamicType).")
//        }
//        return try self.init(dictionary: dictionary)
//    }
//}
//
//// This class only exists to eliminate need of overriding init() and to aide in subclassing.
//// It's technically possible to subclass without subclassing RetroluxObject, but it was disabled to prevent
//// hard-to-find corner cases that might crop up. In particular, the issue where protocols with default implementations
//// and subclassing doesn't work well together (default implementation will be used in some cases where it might
//// come as a surprise).
//public class RetroluxObject: NSObject, Serializable {
//    public required override init() {
//        super.init()
//    }
//    
//    public required convenience init(dictionary: [String: AnyObject]) throws {
//        self.init()
//        try Retrolux.serializer.setPropertiesFor(instance: self, fromDictionary: dictionary)
//    }
//    
//    public func toDictionary() throws -> [String: AnyObject] {
//        return try Retrolux.serializer.serializeToDictionary(self)
//    }
//    
//    public func toData() throws -> NSData {
//        return try Retrolux.serializer.serializeToData(self)
//    }
//    
//    public func toString() throws -> String {
//        return try Retrolux.serializer.serializeToString(self)
//    }
//    
//    public func validate() -> ErrorMessage? {
//        return nil
//    }
//    
//    public class var ignoredProperties: [String] {
//        return ignoreErrorsForProperties
//    }
//    
//    public class var ignoreErrorsForProperties: [String] {
//        return []
//    }
//    
//    public class var mappedProperties: [String: String] {
//        return [:]
//    }
//    
//    @available(*, deprecated=1.0, message="Will be removed in v0.1.0")
//    public class func fromNetworkResponse(object: AnyObject) throws -> Any {
//        guard let dictionary = object as? [String: AnyObject] else {
//            throw RetroluxException.SerializerError(message: "Cannot convert response of type \(object.dynamicType) into a \(self.dynamicType).")
//        }
//        return try self.init(dictionary: dictionary)
//    }
//}
//
//public class Serializer {
//    public enum TransformDirection {
//        case ToDictionary
//        case FromDictionary
//    }
//    
//    public static let sharedInstance = Serializer()
//    
//    public var dateFormatters: [NSDateFormatter] = {
//        let locale = NSLocale(localeIdentifier: "en_US_posix")
//        
//        let f1 = NSDateFormatter()
//        f1.locale = locale
//        f1.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
//        
//        let f2 = NSDateFormatter()
//        f2.locale = locale
//        f2.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
//        
//        return [f1, f2]
//    }()
//    
//    public var cache: [ObjectIdentifier: [Property]] = [:]
//    
//    public func getObjectType(from object: Serializable, property: String) -> Serializable? {
//        return nil
//    }
//    
//    public func getProperties(fromType type: Serializable.Type) throws -> [Property] {
//        let identifier = ObjectIdentifier(type)
//        if let properties = cache[identifier] {
//            // Cached already
//            return properties
//        }
//        
//        // Add to cache
//        let properties = try serializationProperties(forInstance: type.init())
//        cache[identifier] = properties
//        return properties
//    }
//    
//    public func serializationProperties(forInstance instance: Serializable) throws -> [Property] {
//       
//    }
//    
//    public func serializeToDictionary(instance: Serializable) throws -> [String: AnyObject] {
//        var output = [String: AnyObject]()
//        for property in try getProperties(fromType: instance.dynamicType) {
//            if let value = instance.valueForKey(property.name) {
//                output[property.dictionaryKey] = try transform(value, type: property.type, direction: .ToDictionary)
//            } else {
//                output[property.dictionaryKey] = NSNull()
//            }
//        }
//        return output
//    }
//    
//    public func serializeToData(instance: Serializable) throws -> NSData {
//        do {
//            let dictionary = try instance.toDictionary()
//            return try NSJSONSerialization.dataWithJSONObject(dictionary, options: [])
//        } catch RetroluxException.SerializerError(let message) {
//            throw RetroluxException.SerializerError(message: "Failed to convert \(instance.dynamicType) to a JSON " +
//                "string: \(message)")
//        } catch let error as NSError {
//            throw RetroluxException.SerializerError(message: "Failed to convert \(instance.dynamicType) to a JSON " +
//                "string: \(error.localizedDescription)")
//        }
//    }
//    
//    public func serializeToString(instance: Serializable) throws -> String {
//        return String(data: try instance.toData(), encoding: NSUTF8StringEncoding)!
//    }
//    
//    public func dictionaryFromData(data: NSData) throws -> [String: AnyObject] {
//        guard let dict = try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [String: AnyObject] else {
//            throw RetroluxException.SerializerError(message: "Wrong type in JSON data for \(self.dynamicType)" +
//                "--expected dictionary.")
//        }
//        return dict
//    }
//    
//    public func arrayFromData(data: NSData) throws -> [[String: AnyObject]] {
//        guard let array = try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [[String: AnyObject]] else {
//            throw RetroluxException.SerializerError(message: "Wrong type in JSON data for \(self.dynamicType)" +
//            "--expected dictionary")
//        }
//        return array
//    }
//    
//    public func setPropertiesFor(instance instance: Serializable, fromDictionary dictionary: [String: AnyObject]) throws {
//        for property in try getProperties(fromType: instance.dynamicType) {
//            var value: AnyObject! = dictionary[property.dictionaryKey]
//            guard value != nil else {
//                guard property.required else {
//                    continue
//                }
//                throw RetroluxException.SerializerError(message: "Missing key \"\(property.name)\" in json for " +
//                    "property \"\(property.name)\" on class \(instance.dynamicType).")
//            }
//            
//            guard property.type.isCompatibleWith(value) else {
//                guard property.required else {
//                    continue
//                }
//                throw RetroluxException.SerializerError(message: "Value " +
//                    "\(value) is not compatible with type \(property.type) for property " +
//                    "\"\(property.name)\" on class \(instance.dynamicType).")
//            }
//            
//            if !(value is NSNull) {
//                do {
//                    value = try transform(value, type: property.type, direction: .FromDictionary)
//                } catch RetroluxException.SerializerError(let message) {
//                    guard property.required else {
//                        continue
//                    }
//                    throw RetroluxException.SerializerError(message: "Failed to convert value for property " +
//                        "\"\(property.name)\" on class \(instance.dynamicType) to a \(property.type): \(message)")
//                }
//            }
//            
//            instance.setValue(value is NSNull ? nil : value, forKey: property.name)
//        }
//        
//        if let error = instance.validate() {
//            throw RetroluxException.SerializerError(message: "Object \(instance) failed validation: \(error)")
//        }
//    }
//}
