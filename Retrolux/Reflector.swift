
//
//  Reflector.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 7/12/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

open class Reflector {
    open var cache: [ObjectIdentifier: [Property]] = [:]
    open var lock = OSSpinLock()
    open class var shared: Reflector {
        struct Static {
            static let instance = Reflector()
        }
        return Static.instance
    }
    
    open var globalTransformers: [TransformerType] = []
    
    open var reflectableTransformer: TransformerType!
    open var urlTransformer: TransformerType!
    
    public init() {
        self.reflectableTransformer = ReflectableTransformer(weakReflector: self)
        self.urlTransformer = URLTransformer()
        
        self.globalTransformers = [
            reflectableTransformer,
            urlTransformer
        ]
    }
    
    open func convert(fromJSONArrayData arrayData: Data, to type: Reflectable.Type) throws -> [Reflectable] {
        let objects_any: Any
        do {
            objects_any = try JSONSerialization.jsonObject(with: arrayData, options: [])
        } catch {
            throw ReflectorSerializationError.invalidJSONData(error)
        }
        guard let objects = objects_any as? [[String: Any]] else {
            assert(objects_any as? [String: Any] != nil)
            throw ReflectorSerializationError.expectedArrayRootButGotDictionaryRoot(type: type)
        }
        return try convert(fromArray: objects, to: type)
    }
    
    open func convert(fromJSONDictionaryData dictionaryData: Data, to type: Reflectable.Type) throws -> Reflectable {
        let object_any: Any
        do {
            object_any = try JSONSerialization.jsonObject(with: dictionaryData, options: [])
        } catch {
            throw ReflectorSerializationError.invalidJSONData(error)
        }
        guard let object = object_any as? [String: Any] else {
            assert(object_any as? [Any] != nil)
            throw ReflectorSerializationError.expectedDictionaryRootButGotArrayRoot(type: type)
        }
        return try convert(fromDictionary: object, to: type)
    }
    
    open func convertToJSONDictionaryData(from instance: Reflectable) throws -> Data {
        let dictionary = try convertToDictionary(from: instance)
        return try JSONSerialization.data(withJSONObject: dictionary, options: [])
    }
    
    open func convertToJSONArrayData(from instances: [Reflectable]) throws -> Data {
        let array = try convertToArray(from: instances)
        return try JSONSerialization.data(withJSONObject: array, options: [])
    }
    
    open func convert(fromArray array: [[String: Any]], to type: Reflectable.Type) throws -> [Reflectable] {
        var output: [Reflectable] = []
        for dictionary in array {
            output.append(try convert(fromDictionary: dictionary, to: type))
        }
        return output
    }
    
    open func convert(fromDictionary dictionary: [String: Any], to type: Reflectable.Type) throws -> Reflectable {
        let instance = type.init()
        let properties = try reflect(instance)
        for property in properties {
            let rawValue = dictionary[property.serializedName]
            try set(value: rawValue, for: property, on: instance)
        }
        return instance
    }
    
    open func convertToArray(from instances: [Reflectable]) throws -> [[String: Any]] {
        var output: [[String: Any]] = []
        for instance in instances {
            output.append(try convertToDictionary(from: instance))
        }
        return output
    }
    
    open func convertToDictionary(from instance: Reflectable) throws -> [String: Any] {
        var dictionary: [String: Any] = [:]
        let properties = try reflect(instance)
        for property in properties {
            let value = try self.value(for: property, on: instance)
            dictionary[property.serializedName] = value
        }
        return dictionary
    }
    
    fileprivate func getMirrorChildren(_ mirror: Mirror, parentMirror: Mirror?) throws -> [(label: String, valueType: Any.Type)] {
        var children = [(label: String, valueType: Any.Type)]()
        if let superMirror = mirror.superclassMirror, superMirror.subjectType is Reflectable.Type {
            children = try getMirrorChildren(superMirror, parentMirror: mirror)
        } else if parentMirror != nil {
            if mirror.subjectType is ReflectableSubclassingIsAllowed.Type == false {
                throw ReflectionError.subclassingNotAllowed(mirror.subjectType)
            }
        }
        
        // Purposefully ignores labels that are nil
        return children + mirror.children.flatMap {
            guard let label = $0.label else {
                return nil
            }
            return (label, type(of: $0.value))
        }
    }
    
    open func reflect(_ instance: Reflectable) throws -> [Property] {
        OSSpinLockLock(&lock)
        defer {
            OSSpinLockUnlock(&lock)
        }
        
        let cacheID = ObjectIdentifier(type(of: instance))
        if let cached = cache[cacheID] {
            return cached
        }
        
        var properties = [Property]()
        let subjectType = type(of: instance)
        let children = try getMirrorChildren(Mirror(reflecting: instance), parentMirror: nil)
        let propertyNameSet: Set<String> = Set(children.map({ $0.label }))
        
        let config = PropertyConfig(validator: { (config, name, options) in
            guard propertyNameSet.contains(name) else {
                throw PropertyConfigValidationError.cannotSetOptionsForNonExistantProperty(propertyName: name, forClass: subjectType)
            }
            
            // Ensure that each property is mapped to a unique key.
            var mappedTo = name
            for option in options {
                if case PropertyConfig.Option.serializedName(let customized) = option {
                    mappedTo = customized
                    // Purposefully no break, because there could be another serialized name later on.
                }
            }
            
            for (otherName, otherOptions) in config.storage {
                for option in otherOptions {
                    if case PropertyConfig.Option.serializedName(let otherMappedTo) = option, mappedTo == otherMappedTo {
                        throw PropertyConfigValidationError.serializedNameAlreadyTaken(propertyName: name, alreadyTakenBy: otherName, serializedName: mappedTo, onClass: subjectType)
                    }
                }
            }
        })
        subjectType.config(config)
        
        outer_loop: for (label, valueType) in children {
            var options = config[label]
            
            if isReadOnly(property: label, instance: instance) {
                options.append(.ignored)
            }
            
            for option in options {
                if case .ignored = option {
                    continue outer_loop
                }
            }
            
            var transformer: TransformerType?
            for option in options {
                if case .transformed(let t) = option {
                    transformer = t
                }
            }
            
            let type = PropertyType.from(valueType)
            let isSupportedType: Bool
            if let transformer = transformer {
                isSupportedType = transformer.supports(propertyType: type)
            } else if case .unknown = type.bottom {
                for t in globalTransformers {
                    if t.supports(propertyType: type) {
                        transformer = t
                        options.append(.transformed(t))
                        break
                    }
                }
                isSupportedType = transformer != nil
            } else {
                isSupportedType = true
            }
            
            if !isSupportedType {
                throw ReflectionError.propertyNotSupported(propertyName: label, type: type, forClass: subjectType)
            }
            
                // We don't know what type this property is, so it's unsupported.
                // The user should probably add this to their list of ignored properties if it reaches this point.
                
//                throw ReflectionError.propertyNotSupported(
//                    propertyName: label,
//                    valueType: valueType,
//                    forClass: subjectType
//                )
//            }
            
            guard instance.responds(to: Selector(label)) else {
                // This property cannot be seen by the Objective-C runtime.
                
                switch type {
                case .optional(let wrapped):
                    // Optional numeric primitives (i.e., Int?) cannot be bridged to Objective-C as of Swift 3.1.0.
                    switch wrapped {
                    case .number(let wrappedType):
                        throw ReflectionError.optionalNumericTypesAreNotSupported(
                            propertyName: label,
                            unwrappedType: wrappedType,
                            forClass: subjectType
                        )
                    case .bool:
                        throw ReflectionError.optionalNumericTypesAreNotSupported(
                            propertyName: label,
                            unwrappedType: Bool.self,
                            forClass: subjectType
                        )
                    default:
                        break
                    }
                default:
                    break
                }
                
                // We have no clue what this property type is.
                throw ReflectionError.propertyNotSupported(
                    propertyName: label,
                    type: type,
                    forClass: subjectType
                )
            }
            
            let property = Property(type: type, name: label, options: options)
            properties.append(property)
        }
        
        cache[cacheID] = properties
        
        return properties
    }
    
    fileprivate func isReadOnly(property: String, instance: Reflectable) -> Bool {
        guard let objc_property = class_getProperty(type(of: instance), property) else {
            return false
        }
        guard let c_attributes = property_getAttributes(objc_property) else {
            return false
        }
        let attributes = String(cString: c_attributes, encoding: String.Encoding.utf8)!
        return attributes.components(separatedBy: ",").contains("R")
    }
    
    open func set(value: Any?, for property: Property, on instance: Reflectable) throws {
        try reflectable_setProperty(property, value: value, instance: instance)
    }
    
    open func value(for property: Property, on instance: Reflectable) throws -> Any {
        return try reflectable_value(for: property, instance: instance) ?? NSNull()
    }
}
