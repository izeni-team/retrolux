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
    case mappedPropertyConflict(properties: [String], conflictKey: String, forClass: Any.Type)
    case unsupportedPropertyValueType(property: String, valueType: Any.Type, forClass: Any.Type)
    case optionalPrimitiveNumberNotBridgable(property: String, forClass: Any.Type)
    
    /*
     If you get this error, try adding dynamic keyword to your property.
     If that still doesn't work, try adding the @objc keyword.
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
        
        let children = try getMirrorChildren(Mirror(reflecting: instance), parentMirror: nil)
        let propertyNameSet: Set<String> = Set(children.map({ $0.label }))
        
        if let ignoredButNotImplemented = ignored.subtracting(propertyNameSet).first {
            throw RLObjectReflectionError.cannotIgnoreNonExistantProperty(
                propertyName: ignoredButNotImplemented,
                forClass: subjectType
            )
        }
        if let optionalButNotImplemented = ignoreErrorsFor.subtracting(propertyNameSet).first {
            throw RLObjectReflectionError.cannotIgnoreErrorsForNonExistantProperty(
                propertyName: optionalButNotImplemented,
                forClass: subjectType
            )
        }
        if let ignoredAndOptional = ignored.intersection(ignoreErrorsFor).first {
            throw RLObjectReflectionError.cannotIgnoreErrorsAndIgnoreProperty(
                propertyName: ignoredAndOptional,
                forClass: subjectType
            )
        }
        if let mappedButNotImplemented = Set(mapped.keys).subtracting(propertyNameSet).first {
            throw RLObjectReflectionError.cannotMapNonExistantProperty(
                propertyName: mappedButNotImplemented,
                forClass: subjectType
            )
        }
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
        
        for (label, valueType) in children {
            guard !ignored.contains(label) else {
                continue
            }
            guard let type = PropertyType.from(valueType) else {
                throw RLObjectReflectionError.unsupportedPropertyValueType(
                    property: label,
                    valueType: valueType,
                    forClass: subjectType
                )
            }
            
            guard instance.responds(to: Selector(label)) else {
                switch type {
                case .optional(let wrapped):
                    switch wrapped {
                    case .bool: fallthrough
                    case .number:
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
                throw RLObjectReflectionError.propertyNotBridgable(
                    property: label,
                    valueType: valueType,
                    forClass: subjectType
                )
            }
            guard !isReadOnly(property: label, instance: instance) else {
                throw RLObjectReflectionError.readOnlyProperty(
                    property: label,
                    forClass: subjectType
                )
            }
            let required = !ignoreErrorsFor.contains(label)
            let finalMappedKey = mapped[label] ?? label
            let property = Property(type: type, name: label, required: required, mappedTo: finalMappedKey)
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
