//
//  ReflectionError.swift
//  Retrolux
//
//  Created by Bryan Henderson on 4/4/17.
//  Copyright © 2017 Bryan. All rights reserved.
//

import Foundation

public enum ReflectionError: RetroluxError {
    case subclassingNotAllowed(Any.Type)
    case cannotIgnoreNonExistantProperty(propertyName: String, forClass: Any.Type)
    case cannotIgnoreErrorsForNonExistantProperty(propertyName: String, forClass: Any.Type)
    case cannotIgnoreErrorsAndIgnoreProperty(propertyName: String, forClass: Any.Type)
    case cannotMapNonExistantProperty(propertyName: String, forClass: Any.Type)
    case cannotTransformNonExistantProperty(propertyName: String, forClass: Any.Type)
    case mappedPropertyConflict(properties: [String], conflictKey: String, forClass: Any.Type)
    case cannotMapAndIgnoreProperty(propertyName: String, forClass: Any.Type)
    case cannotTransformAndIgnoreProperty(propertyName: String, forClass: Any.Type)
    case optionalNumericTypesAreNotSupported(propertyName: String, unwrappedType: Any.Type, forClass: Any.Type)
    
    /*
     If you get this error, try adding dynamic keyword to your property.
     If that still doesnt work, try adding the dynamic (or @objc) attribute.
     If that STILL doesnt work, your property type is not supported. :-(
     */
    case propertyNotSupported(propertyName: String, type: PropertyType, forClass: Any.Type)
    
    public var rl_error: RetroluxErrorDescription {
        switch self {
        case .subclassingNotAllowed(let `class`):
            return RetroluxErrorDescription(
                description: "Subclassing is not allowed for \(`class`).",
                suggestion: "If you wish to proceed anyways, and you understand the risks and subclassing quirks, make \(`class`) conform to \(ReflectableSubclassingIsAllowed.self)."
            )
        case .cannotIgnoreNonExistantProperty(propertyName: let propertyName, forClass: let `class`):
            return RetroluxErrorDescription(
                description: "The property '\(propertyName)' on \(`class`) cannot be marked as ignored, because no such property exists.",
                suggestion: "Either remove the property '\(propertyName)' on class \(`class`), or remove '\(propertyName)' from the list of ignored properties."
            )
        case .cannotIgnoreErrorsForNonExistantProperty(propertyName: let propertyName, forClass: let `class`):
            return RetroluxErrorDescription(
                description: "The property '\(propertyName)' on \(`class`) cannot be marked as errors allowed, because no such property exists.",
                suggestion: "Either create a property '\(propertyName)' on class \(`class`), or remove '\(propertyName)' from the list of properties where errors are allowed."
            )
        case .cannotIgnoreErrorsAndIgnoreProperty(propertyName: let propertyName, forClass: let `class`):
            return RetroluxErrorDescription(
                description: "The property '\(propertyName)' on \(`class`) cannot be marked as ignored and allow errors.",
                suggestion: "Either remove the property '\(propertyName)' on class \(`class`), or remove it from the list of ignored properties, or remove it from the list of properties where errors are allowed."
            )
        case .cannotMapNonExistantProperty(propertyName: let propertyName, forClass: let `class`):
            return RetroluxErrorDescription(
                description: "The property '\(propertyName)' on \(`class`) cannot be remapped, because no such property exists.",
                suggestion: "Either create a property '\(propertyName)' on class \(`class`), or remove it from the list of remapped properties."
            )
        case .cannotTransformNonExistantProperty(propertyName: let propertyName, forClass: let `class`):
            return RetroluxErrorDescription(
                description: "The property '\(propertyName)' on \(`class`) cannot be transformed, because no such property exists.",
                suggestion: "Either create a property '\(propertyName)' on \(`class`), or remove the transformer."
            )
        case .cannotTransformAndIgnoreProperty(propertyName: let propertyName, forClass: let `class`):
            return RetroluxErrorDescription(
                description: "The property '\(propertyName)' on \(`class`) cannot be ignored and transformed.",
                suggestion: "Either remove the property '\(propertyName)' on \(`class`), or remove it from the list of remapped properties, or remove the transformer."
            )
        case .mappedPropertyConflict(properties: let properties, conflictKey: let conflictKey, forClass: let `class`):
            return RetroluxErrorDescription(
                description: "The properties, \(properties), on class \(`class`), all map to the same key, \"\(conflictKey)\".",
                suggestion: "Change the values of the remapped properties, \(properties), on \(`class`), such that each property is mapped to a unique value (currently, all are assigned to the key, \"\(conflictKey)\")."
            )
        case .cannotMapAndIgnoreProperty(propertyName: let propertyName, forClass: let `class`):
            return RetroluxErrorDescription(
                description: "The property '\(propertyName)' on class \(`class`) cannot be ignored and remapped.",
                suggestion: "Either remove the property '\(propertyName)' on \(`class`), or remove it from the list of remapped properties, or remove it from the list of ignored properties."
            )
        case .optionalNumericTypesAreNotSupported(propertyName: let propertyName, unwrappedType: let unwrappedType, forClass: let `class`):
            return RetroluxErrorDescription(
                description: "The property '\(propertyName)' on class \(`class`) has type \(unwrappedType)?, which isn't supported as an optional.",
                suggestion: "Either change the type of the property '\(propertyName)' on \(`class`) to \(unwrappedType) (like `var \(propertyName) = \(unwrappedType)()`), or make it an optional NSNumber (i.e., NSNumber?), or add it to the list of ignored properties."
            )
        case .propertyNotSupported(propertyName: let propertyName, type: let type, forClass: let `class`):
            return RetroluxErrorDescription(
                description: "The property '\(propertyName)' on class \(`class`) has an unsupported type, \(type).",
                suggestion: "Change the type of the property '\(propertyName)' on \(`class`) to a supported type, or create a transformer that supports the property's type, \(type), or add it to the list of ignored properties. To see a more descriptive reason for why this property isn't supported, try adding the @objc attribute to your property and see if the compiler reveals any new errors."
            )
        }
    }
}
