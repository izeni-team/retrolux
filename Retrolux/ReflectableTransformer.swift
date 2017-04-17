//
//  ReflectableTransformer.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 10/16/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

open class ReflectableTransformer: NestedTransformer {
    public typealias TypeOfProperty = Reflectable
    public typealias TypeOfData = [String: Any]
    
    open weak var reflector: Reflector?
    
    public init(weakReflector: Reflector) {
        self.reflector = weakReflector
    }
    
    public func setter(_ dataValue: TypeOfData, type: Any.Type) throws -> TypeOfProperty {
        return try reflector!.convert(fromDictionary: dataValue, to: type as! TypeOfProperty.Type)
    }
    
    public func getter(_ propertyValue: TypeOfProperty) throws -> [String : Any] {
        return try reflector!.convertToDictionary(from: propertyValue)
    }
}
