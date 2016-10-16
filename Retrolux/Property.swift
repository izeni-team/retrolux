//
//  Property.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 7/12/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

// Though this class is hashable and equatable, do note that if two properties are the same on two different
// classes, they will be considered "equal."
open class Property: Hashable, Equatable {
    // This is a recursive enum that describes the type of the property.
    open let type: PropertyType
    
    // This is the key name of the property as it was typed on the class itself.
    open let name: String
    
    // If this is true, then if the value is missing or an incompatible type, then an error will be raised.
    // If this is false, then when an error occurs the value will be not be assigned and left with its default value.
    open let required: Bool
    
    // Allows you to specify a different data key than what the property's name is. This is useful for JSON when
    // you want your properties to be camelCased but they are underscore_separated in JSON.
    //
    // By default, this should be the same as the property name unless the user specifies otherwise.
    open let mappedTo: String
    
    // Hashable confirmance.
    open let hashValue: Int
    
    // Whether or not this value has a transformer.
    open let transformer: ValueTransformer?
    
    public init(type: PropertyType, name: String, required: Bool, mappedTo: String, transformer: ValueTransformer?) {
        self.type = type
        self.name = name
        self.required = required
        self.mappedTo = mappedTo
        self.transformer = transformer
        
        // Classes cannot have more than one property with the same name, so this *probably* won't have any collisions
        // with other hashes (unless you merge properties from multiple classes--then in that case collisions would
        // be possible).
        self.hashValue = name.hashValue
    }
}

public func ==(lhs: Property, rhs: Property) -> Bool {
    return lhs.name == rhs.name && lhs.type == rhs.type && lhs.required == rhs.required && lhs.mappedTo == rhs.mappedTo
}
