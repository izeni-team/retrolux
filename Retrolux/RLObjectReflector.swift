//
//  RLObjectReflector.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 7/12/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

public enum RLObjectReflectionError: Error {
    case unsupportedBaseClass(Any.Type)
    case cannotIgnoreNonExistantProperty(propertyName: String, forClass: Any.Type)
    case cannotIgnoreErrorsForNonExistantProperty(propertyName: String, forClass: Any.Type)
    case cannotIgnoreErrorsAndIgnoreProperty(propertyName: String, forClass: Any.Type)
    case cannotMapNonExistantProperty(propertyName: String, forClass: Any.Type)
    case cannotTransformNonExistantProperty(propertyName: String, forClass: Any.Type)
    case mappedPropertyConflict(properties: [String], conflictKey: String, forClass: Any.Type)
    case cannotMapAndIgnoreProperty(propertyName: String, forClass: Any.Type)
    case cannotTransformAndIgnoreProperty(propertyName: String, forClass: Any.Type)
    case unsupportedPropertyValueType(property: String, valueType: Any.Type, forClass: Any.Type)
    case optionalPrimitiveNumberNotBridgable(property: String, forClass: Any.Type)
    
    /*
     If you get this error, try adding dynamic keyword to your property.
     If that still doesn't work, try adding the dynamic (or @objc) attribute.
     If that STILL doesn't work, your property type is not supported. :-(
     */
    case propertyNotBridgable(property: String, valueType: Any.Type, forClass: Any.Type)
    
    case readOnlyProperty(property: String, forClass: Any.Type)
}

open class RLObjectReflector {
    public init() {}
    
    fileprivate func getMirrorChildren(_ mirror: Mirror, parentMirror: Mirror?) throws -> [(label: String, valueType: Any.Type)] {
        var children = [(label: String, valueType: Any.Type)]()
        if let superMirror = mirror.superclassMirror, superMirror.subjectType is RLObjectProtocol.Type {
            children = try getMirrorChildren(superMirror, parentMirror: mirror)
        } else if let parent = parentMirror, parent.subjectType is RLObjectProtocol.Type && mirror.subjectType != RLObject.self {
            throw RLObjectReflectionError.unsupportedBaseClass(mirror.subjectType)
        }
        
        // Purposefully ignores labels that are nil
        return children + mirror.children.flatMap {
            guard let label = $0.label else {
                return nil
            }
            return (label, type(of: $0.value))
        }
    }
    
    open func reflect(_ instance: RLObjectProtocol) throws -> [Property] {
        var properties = [Property]()
        let subjectType = type(of: instance)
        
        let ignored = Set(subjectType.ignoredProperties)
        let ignoreErrorsFor = Set(subjectType.ignoreErrorsForProperties)
        let mapped = subjectType.mappedProperties
        let transformed = subjectType.transformedProperties
        
        let children = try getMirrorChildren(Mirror(reflecting: instance), parentMirror: nil)
        let propertyNameSet: Set<String> = Set(children.map({ $0.label }))
        
        // We *could* silently ignore the users request to ignore a non-existant property, but it's possible that
        // they simply misspelled it. Raise an error just to be safe.
        if let ignoredButNotImplemented = ignored.subtracting(propertyNameSet).first {
            throw RLObjectReflectionError.cannotIgnoreNonExistantProperty(
                propertyName: ignoredButNotImplemented,
                forClass: subjectType
            )
        }
        
        // A non-existant property is not considered an error that can be ignored. It probably indicates a mistake
        // on the user's part.
        if let optionalButNotImplemented = ignoreErrorsFor.subtracting(propertyNameSet).first {
            throw RLObjectReflectionError.cannotIgnoreErrorsForNonExistantProperty(
                propertyName: optionalButNotImplemented,
                forClass: subjectType
            )
        }
        
        // Check if the user has requested to completely ignore a property AS WELL as ignore only the errors.
        if let ignoredAndOptional = ignored.intersection(ignoreErrorsFor).first {
            throw RLObjectReflectionError.cannotIgnoreErrorsAndIgnoreProperty(
                propertyName: ignoredAndOptional,
                forClass: subjectType
            )
        }
        
        // Check if the user has requested to remap a property that doesn't exist.
        if let mappedButNotImplemented = Set(mapped.keys).subtracting(propertyNameSet).first {
            throw RLObjectReflectionError.cannotMapNonExistantProperty(
                propertyName: mappedButNotImplemented,
                forClass: subjectType
            )
        }
        
        if let transformedButNotImplemented = Set(transformed.keys).subtracting(propertyNameSet).first {
            throw RLObjectReflectionError.cannotTransformNonExistantProperty(
                propertyName: transformedButNotImplemented,
                forClass: subjectType
            )
        }
        
        // We cannot possibly map one property to multiple values.
        let excessivelyMapped = mapped.filter { k1, v1 in mapped.contains { v1 == $1 && k1 != $0 } }
        if !excessivelyMapped.isEmpty {
            let pickOne = excessivelyMapped.first!.1
            let propertiesForIt = excessivelyMapped.filter { $1 == pickOne }.map { $0.0 }
            throw RLObjectReflectionError.mappedPropertyConflict(
                properties: propertiesForIt,
                conflictKey: pickOne,
                forClass: subjectType
            )
        }
        
        // Ignoring and mapping a property doesn't make sense and might indicate a user error.
        if let ignoredAndMapped = ignored.intersection(mapped.keys).first {
            throw RLObjectReflectionError.cannotMapAndIgnoreProperty(
                propertyName: ignoredAndMapped,
                forClass: subjectType
            )
        }
        
        if let transformedAndIgnored = ignored.intersection(transformed.keys).first {
            throw RLObjectReflectionError.cannotTransformAndIgnoreProperty(
                propertyName: transformedAndIgnored,
                forClass: subjectType
            )
        }
        
        for (label, valueType) in children {
            if ignored.contains(label) {
                continue
            }
            
            var transformer: ValueTransformer?
            if let custom = transformed[label] {
                transformer = custom
            } else {
                transformer = RLObjectTransformer()
            }
                        
            var transformerMatched = false
            guard let type = PropertyType.from(valueType, transformer: transformer, transformerMatched: &transformerMatched) else {
                // We don't know what type this property is, so it's unsupported.
                // The user should probably add this to their list of ignored properties if it reaches this point.
                
                throw RLObjectReflectionError.unsupportedPropertyValueType(
                    property: label,
                    valueType: valueType,
                    forClass: subjectType
                )
            }
            
            if !transformerMatched {
                // Don't save to the property.
                transformer = nil
            }
            
            // TODO: At this point, we should validate that the transformer, if it exists, is being used properly
            // in the property type.
            
            guard instance.responds(to: Selector(label)) else {
                // This property cannot be seen by the Objective-C runtime.
                
                switch type {
                case .optional(let wrapped):
                    switch wrapped {
                    case .number, .bool:
                        // Optional primitives cannot be bridged to Objective-C as of Swift 3.0.0 (Xcode 8.0).
                        // It might change in Swift 3.0.1 (Xcode 8.1).
                        // https://github.com/apple/swift-evolution/blob/master/proposals/0139-bridge-nsnumber-and-nsvalue.md
                        throw RLObjectReflectionError.optionalPrimitiveNumberNotBridgable(
                            property: label,
                            forClass: subjectType
                        )
                    default:
                        break
                    }
                default:
                    break
                }
                
                // We have no clue what this property type is.
                throw RLObjectReflectionError.propertyNotBridgable(
                    property: label,
                    valueType: valueType,
                    forClass: subjectType
                )
            }
            
            guard !isReadOnly(property: label, instance: instance) else {
                // This property is read-only, which means it is not settable.
                // It's *possible* the user doesn't care if we ignore it, but that'd be a bad thing to assume. Better
                // safe than sorry.
                throw RLObjectReflectionError.readOnlyProperty(
                    property: label,
                    forClass: subjectType
                )
            }
            let required = !ignoreErrorsFor.contains(label)
            let finalMappedKey = mapped[label] ?? label
            let property = Property(type: type, name: label, required: required, mappedTo: finalMappedKey, transformer: transformer)
            properties.append(property)
        }
        
        return properties
    }
    
    fileprivate func isReadOnly(property: String, instance: RLObjectProtocol) -> Bool {
        let objc_property = class_getProperty(type(of: instance), property)
        let c_attributes = property_getAttributes(objc_property)!
        let attributes = String(cString: c_attributes, encoding: String.Encoding.utf8)!
        return attributes.components(separatedBy: ",").contains("R")
    }
}
