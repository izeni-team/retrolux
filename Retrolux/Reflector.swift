
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
        try instance.afterDeserialization(remoteData: dictionary)
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
        try instance.afterSerialization(remoteData: &dictionary)
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
    
    open func copy<T: Reflectable>(_ reflectable: T) throws -> T {
        let dictionary = try convertToDictionary(from: reflectable)
        return try convert(fromDictionary: dictionary, to: T.self) as! T
    }
    
    // See documentation for diff(from: [String: Any], to: [String: Any]) for what granular does.
    open func diff(from r1: Reflectable, to r2: Reflectable, granular: Bool = true) throws -> [String: Any] {
        let d1 = try convertToDictionary(from: r1)
        let d2 = try convertToDictionary(from: r2)
        return diff(from: d1, to: d2, granular: granular)
    }
    
    // If granular is false, then if ANY key in _nested_ dictionaries is different,
    // then the ENTIRE nested dictionary will be in the resulting dictionary.
    // If granular is true, then only differences in nested dictionaries
    // will be in the resulting dictionary.
    //
    // Granular only affects nested diffs. Regardless of what granular's value is, the top level is
    // always granular. If you don't like this, you can just do == on the two dictionaries. :-)
    open func diff(from d1: [String: Any], to d2: [String: Any], granular: Bool = true) -> [String: Any] {
        var result = [String: Any]()
        let d1Keys = Set(d1.keys)
        let d2Keys = Set(d2.keys)
        let allKeys = d1Keys.union(d2Keys)
        for key in allKeys {
            if d1Keys.contains(key), !d2Keys.contains(key) {
                result[key] = NSNull()
            } else if !d1Keys.contains(key), d2Keys.contains(key) {
                result[key] = d2[key]
            } else if d1[key] is NSNull, d2[key] is NSNull {
                continue
            } else if d1[key] is NSNull, d2[key] is NSNull == false {
                result[key] = d2[key]
            } else if d1[key] is NSNull == false, d2[key] is NSNull {
                result[key] = NSNull()
            } else {
                // The actual values are different, and neither are null.
                if d1[key] is [String: Any], granular {
                    let d = diff(from: d1[key] as! [String: Any], to: d2[key] as! [String: Any])
                    if !d.isEmpty {
                        result[key] = d
                    }
                } else if d1[key] is [Any] {
                    let d1_array = d1[key] as! [Any]
                    let d2_array = d2[key] as! [Any]
                    
                    if d1_array.count != d2_array.count {
                        result[key] = d2_array
                    } else if NSArray(array: d1_array) != NSArray(array: d2_array) {
                        result[key] = d2_array
                    }
                } else if d1[key] as! NSObject != d2[key] as! NSObject {
                    result[key] = d2[key]
                }
            }
        }
        return result
    }
    
    /// WARNING: Does not call afterDeserialization or afterSerialization.
    open func update(_ reflectable: Reflectable, with other: Reflectable) throws {
        let properties = try reflect(reflectable)
        let otherProperties = try reflect(other)
        for property in properties {
            if let otherProperty = otherProperties.first(where: { $0.serializedName == property.serializedName }) {
                let otherValue = try value(for: otherProperty, on: other)
                try set(value: otherValue, for: property, on: reflectable)
            }
        }
    }
}
