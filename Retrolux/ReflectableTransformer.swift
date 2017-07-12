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
    
    // We have to override this because of a Swift bug that prevents the default implementation
    // in NestedTransformer from working properly. As of Swift 3.1.0.
    open func supports(propertyType: PropertyType) -> Bool {
        if case .unknown(let type) = propertyType.bottom {
            return type is Reflectable.Type
        }
        return false
    }
    
    open func setter(_ dataValue: TypeOfData, type: Any.Type) throws -> TypeOfProperty {
        return try reflector!.convert(fromDictionary: dataValue, to: type as! TypeOfProperty.Type)
    }
    
    open func getter(_ propertyValue: TypeOfProperty) throws -> [String : Any] {
        return try reflector!.convertToDictionary(from: propertyValue)
    }
}
