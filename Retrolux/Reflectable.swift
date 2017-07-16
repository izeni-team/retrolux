//
//  Reflectable.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 7/12/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

public func reflectable_setProperty(_ property: Property, value: Any?, instance: Reflectable) throws {
    if property.ignored {
        return
    }
    
    guard property.type.isCompatible(with: value, transformer: property.transformer) else {
        if case .optional(let wrapped) = property.type {
            /* Nothing */ // TODO: This needs a unit test, and isn't correct behavior.
            
        } else if value == nil {
            throw ReflectorSerializationError.keyNotFound(propertyName: property.name, key: property.serializedName, forClass: type(of: instance))
        } else if value is NSNull {
            if !property.nullable {
                throw ReflectorSerializationError.propertyDoesNotSupportNullValues(propertyName: property.name, forClass: type(of: instance))
            }
        } else {
            throw ReflectorSerializationError.typeMismatch(expected: property.type, got: type(of: value), propertyName: property.name, forClass: type(of: instance))
        }
        return
    }
    
    guard let value = value, value is NSNull == false else {
        instance.setValue(nil, forKey: property.name)
        return
    }
    
    if let transformer = property.transformer {
        try transformer.set(value: value, for: property, instance: instance)
    } else {
        instance.setValue(value, forKey: property.name)
    }
}

public func reflectable_value(for property: Property, instance: Reflectable) throws -> Any? {
    if let transformer = property.transformer {
        return try transformer.value(for: property, instance: instance)
    }
    return instance.value(forKey: property.name)
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
    
    /// Use this to make customizations to the object on a worker queue after
    /// deserialization from remote data to a class is complete.
    func afterDeserialization(remoteData: [String: Any]) throws
    
    /// Use this to make customizations to the remote data on a worker queue after
    /// serialization from a class to remote data is complete.
    func afterSerialization(remoteData: inout [String: Any]) throws
    
    func validate() throws
    static func config(_ c: PropertyConfig)
}

extension Reflectable {
    public func validate() throws {
        
    }
    
    public static func config(_ c: PropertyConfig) {
        
    }
    
    public func afterDeserialization(remoteData: [String: Any]) throws {
        
    }
    
    public func afterSerialization(remoteData: inout [String: Any]) throws {
        
    }
}
