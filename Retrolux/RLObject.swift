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
public class RLObject: NSObject, RLObjectProtocol {
    public required override init() {
        super.init()
    }
    
    public func set(value value: Any?, forProperty property: Property) throws {
        try rlobj_setProperty(property, value: value, instance: self)
    }
    
    public func valueFor(property: Property) -> Any? {
        return valueForKey(property.name)
    }
    
    public func validate() -> String? {
        return nil
    }
    
    public class var ignoredProperties: [String] {
        return ignoreErrorsForProperties
    }
    
    public class var ignoreErrorsForProperties: [String] {
        return []
    }
    
    public class var mappedProperties: [String: String] {
        return [:]
    }
}