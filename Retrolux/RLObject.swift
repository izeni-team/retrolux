//
//  RLObject.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 7/12/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

// This class only exists to eliminate need of overriding init() and to aide in subclassing.
// It's technically possible to subclass without subclassing RLObject, but it was disabled to prevent
// hard-to-find corner cases that might crop up. In particular, the issue where protocols with default implementations
// and subclassing doesn't work well together (default implementation will be used in some cases even if you provide
// your own implementation later down the road).
open class RLObject: NSObject, RLObjectProtocol {
    public required override init() {
        super.init()
    }

    open func properties() throws -> [Property] {
        return try rlobj_propertiesFor(self)
    }
    
    open func set(value: Any?, forProperty property: Property) throws {
        try rlobj_setProperty(property, value: value, instance: self)
    }
    
    open func value(for property: Property) -> Any? {
        return value(forKey: property.name)
    }
    
    open func validate() -> String? {
        return nil
    }
    
    open class var ignoredProperties: [String] {
        return []
    }
    
    open class var ignoreErrorsForProperties: [String] {
        return []
    }
    
    open class var mappedProperties: [String: String] {
        return [:]
    }
}
