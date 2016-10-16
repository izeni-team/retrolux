//
//  RLObjectValueTransformer.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 10/16/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

public struct RLObjectValueTransformer: PropertyValueTransformer {
    public init() {}
    
    public func supports(targetType: Any.Type) -> Bool {
        return targetType is RLObjectProtocol.Type
    }
    
    public func supports(value: Any, targetType: Any.Type, direction: PropertyValueTransformerDirection) -> Bool {
        switch direction {
        case .forwards:
            return value is [String: Any]
        case .backwards:
            return value is RLObjectProtocol
        }
    }
    
    public func transform(_ value: Any, targetType: Any.Type, direction: PropertyValueTransformerDirection) throws -> Any {
        switch direction {
        case .forwards:
            // TODO: Need target type to be able to code.
            let protoType = targetType as! RLObjectProtocol.Type
            print(value)
            let dictionary = value as! [String: Any]
            print(type(of: value))
            print(dictionary)
            
            let newInstance = protoType.init()
            let properties = try newInstance.properties()
            for property in properties {
                print("Assigning \(dictionary[property.mappedTo]) to \(property.name)")
                try newInstance.set(value: dictionary[property.mappedTo], for: property)
            }
            return newInstance
        case .backwards:
            guard let object = value as? RLObjectProtocol else {
                throw RLObjectError.missingDataKey(requiredProperty: "", forClass: Int.self)
            }
            var output: [String: Any] = [:]
            for property in try object.properties() {
                output[property.mappedTo] = object.value(for: property) ?? NSNull()
            }
            return output
        }
    }
}
