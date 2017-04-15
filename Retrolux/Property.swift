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
open class Property {
    // This is a recursive enum that describes the type of the property.
    open let type: PropertyType
    
    // This is the key name of the property as it was typed on the class itself.
    open let name: String
    
    open let options: [PropertyConfig.Option]
    
    open var ignored: Bool {
        for option in options {
            if case .ignored = option {
                return true
            }
        }
        return false
    }
    
    open var serializedName: String {
        var mappedTo = name
        for option in options {
            if case .serializedName(let newName) = option {
                mappedTo = newName
            }
        }
        return mappedTo
    }
    
    open var transformer: TransformerType? {
        for option in options {
            if case PropertyConfig.Option.transformed(let transformer) = option {
                return transformer
            }
        }
        return nil
    }
    
    open var nullable: Bool {
        for option in options {
            if case .nullable = option {
                return true
            }
        }
        return false
    }
    
    public init(type: PropertyType, name: String, options: [PropertyConfig.Option]) {
        self.type = type
        self.name = name
        self.options = options
    }
}
