//
//  Property.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 7/12/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

public class Property: Hashable, Equatable {
    public let type: PropertyType
    public let name: String
    public let required: Bool
    public let mappedTo: String
    public let hashValue: Int
    
    public init(type: PropertyType, name: String, required: Bool, mappedTo: String) {
        self.type = type
        self.name = name
        self.required = required
        self.mappedTo = mappedTo
        self.hashValue = name.hashValue
    }
}

public func ==(lhs: Property, rhs: Property) -> Bool {
    return lhs.name == rhs.name
}