//
//  RLObjectReflector.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 7/12/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

public enum RLObjectReflectionError: ErrorType {
    case UnsupportedBaseClass(Any.Type)
    case CannotIgnoreNonExistantProperty(propertyName: String, forClass: Any.Type)
    case CannotIgnoreErrorsForNonExistantProperty(propertyName: String, forClass: Any.Type)
    case CannotIgnoreErrorsAndIgnoreProperty(propertyName: String, forClass: Any.Type)
    case CannotMapNonExistantProperty(propertyName: String, forClass: Any.Type)
    case MappedPropertyConflict(properties: [String], conflictKey: String, forClass: Any.Type)
    case UnsupportedPropertyValueType(property: String, valueType: Any.Type, forClass: Any.Type)
    case OptionalPrimitiveNumberNotBridgable(property: String, forClass: Any.Type)
    
    /*
     If you get this error, try adding dynamic keyword to your property.
     If that still doesn't work, try adding the @objc keyword.
     If that STILL doesn't work, your property type is not supported. :-(
     */
    case PropertyNotBridgable(property: String, valueType: Any.Type, forClass: Any.Type)
    
    case ReadOnlyProperty(property: String, forClass: Any.Type)
}

public class RLObjectReflector {
    public init() {
        
    }
    
    private func getMirrorChildren(mirror: Mirror, parentMirror: Mirror?) throws -> [(label: String, valueType: Any.Type)] {
        var children = [(label: String, valueType: Any.Type)]()
        if let superMirror = mirror.superclassMirror() where superMirror.subjectType is RLObjectProtocol.Type {
            children = try getMirrorChildren(superMirror, parentMirror: mirror)
        } else if let parent = parentMirror
            where parent.subjectType is RLObjectProtocol.Type && mirror.subjectType != RLObject.self {
            throw RLObjectReflectionError.UnsupportedBaseClass(mirror.subjectType)
        }
        
        // Purposefully ignores labels that are nil
        return children + mirror.children.flatMap {
            guard let label = $0.label else {
                return nil
            }
            return (label, $0.value.dynamicType)
        }
    }
    
    public func reflect(instance: RLObjectProtocol) throws -> [Property] {
        var properties = [Property]()
        let subjectType = instance.dynamicType
        
        let ignored = Set(subjectType.ignoredProperties)
        let ignoreErrorsFor = Set(subjectType.ignoreErrorsForProperties)
        let mapped = subjectType.mappedProperties
        
        let children = try getMirrorChildren(Mirror(reflecting: instance), parentMirror: nil)
        let propertyNameSet: Set<String> = Set(children.map({ $0.label }))
        
        if let ignoredButNotImplemented = ignored.subtract(propertyNameSet).first {
            throw RLObjectReflectionError.CannotIgnoreNonExistantProperty(
                propertyName: ignoredButNotImplemented,
                forClass: subjectType
            )
        }
        if let optionalButNotImplemented = ignoreErrorsFor.subtract(propertyNameSet).first {
            throw RLObjectReflectionError.CannotIgnoreErrorsForNonExistantProperty(
                propertyName: optionalButNotImplemented,
                forClass: subjectType
            )
        }
        if let ignoredAndOptional = ignored.intersect(ignoreErrorsFor).first {
            throw RLObjectReflectionError.CannotIgnoreErrorsAndIgnoreProperty(
                propertyName: ignoredAndOptional,
                forClass: subjectType
            )
        }
        if let mappedButNotImplemented = Set(mapped.keys).subtract(propertyNameSet).first {
            throw RLObjectReflectionError.CannotMapNonExistantProperty(
                propertyName: mappedButNotImplemented,
                forClass: subjectType
            )
        }
        let excessivelyMapped = mapped.filter { k1, v1 in mapped.contains { v1 == $1 && k1 != $0 } }
        if !excessivelyMapped.isEmpty {
            let pickOne = excessivelyMapped.first!.1
            let propertiesForIt = excessivelyMapped.filter { $1 == pickOne }.map { $0.0 }
            throw RLObjectReflectionError.MappedPropertyConflict(
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
                throw RLObjectReflectionError.UnsupportedPropertyValueType(
                    property: label,
                    valueType: valueType,
                    forClass: subjectType
                )
            }
            
            guard instance.respondsToSelector(Selector(label)) else {
                switch type {
                case .optional(let wrapped):
                    switch wrapped {
                    case .bool: fallthrough
                    case .number:
                        throw RLObjectReflectionError.OptionalPrimitiveNumberNotBridgable(
                            property: label,
                            forClass: subjectType
                        )
                    default:
                        break
                    }
                default:
                    break
                }
                throw RLObjectReflectionError.PropertyNotBridgable(
                    property: label,
                    valueType: valueType,
                    forClass: subjectType
                )
            }
            guard !isReadOnly(property: label, instance: instance) else {
                throw RLObjectReflectionError.ReadOnlyProperty(
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
    
    private func isReadOnly(property property: String, instance: RLObjectProtocol) -> Bool {
        let objc_property = class_getProperty(instance.dynamicType, property)
        let c_attributes = property_getAttributes(objc_property)
        let attributes = String(CString: c_attributes, encoding: NSUTF8StringEncoding)!
        return attributes.componentsSeparatedByString(",").contains("R")
    }
}