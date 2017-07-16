//
//  Reflection.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 7/12/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

// Subclassing Reflectable objects exposes a limitation of Swift protocols:
// Consider the example:
//
//     class Base: NSObject, Reflectable {
//         /* Nothing */
//     }
//
//     class Person: Base {
//         ...
//         var ignored = SomeUnsupportedType()
//         ...
//         static var ignoredProperties: [String] {
//             return ["ignored"]
//         }
//     }
//     
// In the above example, the reflector will be unable to read Person.ignoredProperties.
// In order for it to work properly, you have to make sure it's implemented in the base
// class and overridden in the subclass, like this:
//
//     class Base: NSObject, Reflectable {
//         class var ignoredProperties: [String] {
//             return []
//         }
//     }
//
//     class Person: Base {
//         ...
//         var ignored = SomeUnsupportedType()
//         ...
//         override class var ignoredProperties: [String] {
//             return ["ignored"]
//         }
//     }
//
// Of the two examples provided here, the first won't work, but the second will. If you understand the
// risks and want to create your own custom base class, make your base class conform to
// ReflectableSubclassingIsAllowed, which will tell the reflector to allow subclassing for your custom
// type. This protocol is here for safety and to prevent people from shooting themselves in the foot
// unknowingly when their functions don't get called properly.
public protocol ReflectableSubclassingIsAllowed {}

// This class only exists to eliminate need of overriding init() and to aide in subclassing.
// It's technically possible to subclass without subclassing Reflection, but it was disabled to prevent
// hard-to-find corner cases that might crop up. In particular, the issue where protocols with default implementations
// and subclassing doesn't work well together (default implementation will be used in some cases even if you provide
// your own implementation later down the road).
open class Reflection: NSObject, Reflectable, ReflectableSubclassingIsAllowed {
    public required override init() {
        super.init()
    }
    
    open func validate() throws {
        
    }
    
    open class func config(_ c: PropertyConfig) {
        
    }
    
    open func afterDeserialization(remoteData: [String : Any]) throws {
        
    }
    
    open func afterSerialization(remoteData: inout [String : Any]) throws {
        
    }
}
