//
//  ReflectionError.swift
//  Retrolux
//
//  Created by Bryan Henderson on 4/4/17.
//  Copyright © 2017 Bryan. All rights reserved.
//

import Foundation

public enum ReflectionError: Error {
    case subclassingNotAllowed(Any.Type)
    case cannotIgnoreNonExistantProperty(propertyName: String, forClass: Any.Type)
    case cannotIgnoreErrorsForNonExistantProperty(propertyName: String, forClass: Any.Type)
    case cannotIgnoreErrorsAndIgnoreProperty(propertyName: String, forClass: Any.Type)
    case cannotMapNonExistantProperty(propertyName: String, forClass: Any.Type)
    case cannotTransformNonExistantProperty(propertyName: String, forClass: Any.Type)
    case mappedPropertyConflict(properties: [String], conflictKey: String, forClass: Any.Type)
    case cannotMapAndIgnoreProperty(propertyName: String, forClass: Any.Type)
    case cannotTransformAndIgnoreProperty(propertyName: String, forClass: Any.Type)
    
    case optionalNumericTypesAreNotSupported(property: String, forClass: Any.Type)
    
    /*
     If you get this error, try adding dynamic keyword to your property.
     If that still doesn't work, try adding the dynamic (or @objc) attribute.
     If that STILL doesn't work, your property type is not supported. :-(
     */
    case propertyNotSupported(property: String, valueType: Any.Type, forClass: Any.Type)
    
    case readOnlyProperty(property: String, forClass: Any.Type)
}
