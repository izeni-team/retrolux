//
//  RLObjectProtocol.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 7/12/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

public enum RLObjectError: Error {
    case typeMismatch(expected: PropertyType, got: Any.Type?, property: String, forClass: Any.Type)
    case missingDataKey(requiredProperty: String, forClass: Any.Type)
}

internal func rlobj_setProperty(_ property: Property, value: Any?, instance: RLObjectProtocol) throws {
    guard property.type.isCompatible(with: value) else {
        guard property.required else {
            // TODO: Set to empty value?
            return
        }
        throw RLObjectError.typeMismatch(expected: property.type, got: type(of: value), property: property.name, forClass: type(of: instance))
    }
    let screened = value is NSNull ? nil : value
    instance.setValue(screened, forKey: property.name)
}

internal func rlobj_propertiesFor(_ instance: RLObjectProtocol) throws -> [Property] {
    // TODO: Cache reflection
    return try RLObjectReflector().reflect(instance)
}

public protocol RLObjectProtocol: NSObjectProtocol, PropertyConvertible {
    // Read/write properties
    func responds(to aSelector: Selector!) -> Bool // To check if property can be bridged to Obj-C
    func setValue(_ value: Any?, forKey key: String) // For JSON -> Object deserialization
    func value(forKey key: String) -> Any? // For Object -> JSON serialization
    
    init() // Required for proper reflection support
    
    // TODO: ?
    //func copy() -> Self // Lower priority--this is primarily for copying/detaching database models
    //func changes() -> [String: AnyObject]
    //var hasChanges: Bool { get }
    //func clearChanges() resetChanges() markAsHavingNoChanges() What to name this thing?
    //func revertChanges() // MAYBE?
    
    func validate() -> String?
    static var ignoredProperties: [String] { get }
    static var ignoreErrorsForProperties: [String] { get }
    static var mappedProperties: [String: String] { get }
}

extension RLObjectProtocol {
    public func properties() throws -> [Property] {
        return try rlobj_propertiesFor(self)
    }
    
    public func set(value: Any?, for property: Property) throws {
        try rlobj_setProperty(property, value: value, instance: self)
    }
    
    public func value(for property: Property) -> Any? {
        return value(forKey: property.name)
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
}
