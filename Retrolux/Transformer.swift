//
//  Transformer.swift
//  Retrolux
//
//  Created by Bryan Henderson on 4/14/17.
//  Copyright © 2017 Bryan. All rights reserved.
//

import Foundation

public class Transformer<P, D>: TransformerType {
    public func supports(propertyType: PropertyType) -> Bool {
        return PropertyType.from(P.self) == propertyType
    }
    
    public func supports(value: Any) -> Bool {
        return value is D
    }
    
    public func supports(propertyType: Any.Type) -> Bool {
        return PropertyType.self == propertyType
    }
    
    private var setter: (D) throws -> P
    private var getter: (P) throws -> D
    
    public init(setter: @escaping (D) throws -> P, getter: @escaping (P) throws -> D) {
        self.setter = setter
        self.getter = getter
    }
    
    public func set(value: Any?, for property: Property, instance: Reflectable) throws {
        let converted = try setter(value as! D)
        try instance.set(value: converted, for: property)
    }
    
    public func value(for property: Property, instance: Reflectable) throws -> Any? {
        return try instance.value(for: property)
    }
}
