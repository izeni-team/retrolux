//
//  TransformerType.swift
//  Retrolux
//
//  Created by Bryan Henderson on 4/14/17.
//  Copyright © 2017 Bryan. All rights reserved.
//

import Foundation

public protocol TransformerType: class {
    func supports(propertyType: PropertyType) -> Bool
    
    func set(value: Any?, for property: Property, instance: Reflectable) throws
    func value(for property: Property, instance: Reflectable) throws -> Any?
}
