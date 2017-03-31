//
//  Reflectable.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 7/12/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

public enum SerializationError: Error {
    case typeMismatch(expected: PropertyType, got: Any.Type?, property: String, forClass: Any.Type)
    case invalidRootJSONType
}

internal func reflectable_setProperty(_ property: Property, value: Any?, instance: Reflectable) throws {
    guard property.type.isCompatible(with: value) else {
        if property.required {
            throw SerializationError.typeMismatch(expected: property.type, got: type(of: value), property: property.name, forClass: type(of: instance))
        }
        return
    }
    
    guard let value = value, value is NSNull == false else {
        instance.setValue(nil, forKey: property.name)
        return
    }
    
    if let transformer = property.transformer {
        let transformed = try reflectable_transform(value, type: property.type, transformer: transformer, direction: .forwards)        
        instance.setValue(transformed, forKey: property.name)
    } else {
        instance.setValue(value, forKey: property.name)
    }
}

internal func reflectable_value(for property: Property, instance: Reflectable) throws -> Any? {
    let rawValue = instance.value(forKey: property.name)
    if let transformer = property.transformer, let rawValue = rawValue {
        let transformed = try reflectable_transform(rawValue, type: property.type, transformer: transformer, direction: .backwards)
        return transformed
    }
    return rawValue ?? NSNull()
}

public protocol Reflectable: NSObjectProtocol {
    // Read/write properties
    func responds(to aSelector: Selector!) -> Bool // To check if property can be bridged to Obj-C
    func setValue(_ value: Any?, forKey key: String) // For JSON -> Reflection deserialization
    func value(forKey key: String) -> Any? // For Reflection -> JSON serialization
    
    init() // Required for proper reflection support
    
    // TODO: Consider adding these functions?
    //func copy() -> Self // Lower priority--this is primarily for copying/detaching database models
    //func changes() -> [String: AnyObject]
    //var hasChanges: Bool { get }
    //func clearChanges() resetChanges() markAsHavingNoChanges() What to name this thing?
    //func revertChanges() // MAYBE?
    
    func validate() -> String?
    static var ignoredProperties: [String] { get }
    static var ignoreErrorsForProperties: [String] { get }
    static var mappedProperties: [String: String] { get }
    static var transformedProperties: [String: ValueTransformer] { get }
    
    func set(value: Any?, for property: Property) throws
    func value(for property: Property) throws -> Any?
}

extension Reflectable {
    public func set(value: Any?, for property: Property) throws {
        try reflectable_setProperty(property, value: value, instance: self)
    }
    
    public func value(for property: Property) throws -> Any? {
        return try reflectable_value(for: property, instance: self)
    }

    // TODO: This isn't internationalizable.
    // Return value is just an error message.
    public func validate() -> String? {
        return nil
    }
    
    public static var ignoredProperties: [String] {
        return []
    }
    
    public static var ignoreErrorsForProperties: [String] {
        return []
    }
    
    public static var mappedProperties: [String: String] {
        return [:]
    }
    
    public static var transformedProperties: [String: ValueTransformer] {
        return [:]
    }
}
