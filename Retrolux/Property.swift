//
//  Property.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 7/12/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

open class Property: Hashable, Equatable {
    open let type: PropertyType
    open let name: String
    open let required: Bool
    open let mappedTo: String
    open let hashValue: Int
    
    public init(type: PropertyType, name: String, required: Bool, mappedTo: String) {
        self.type = type
        self.name = name
        self.required = required
        self.mappedTo = mappedTo
        self.hashValue = name.hashValue
    }
}

public func ==(lhs: Property, rhs: Property) -> Bool {
    return lhs.name == rhs.name && lhs.type == rhs.type && lhs.required == rhs.required && lhs.mappedTo == rhs.mappedTo
}
