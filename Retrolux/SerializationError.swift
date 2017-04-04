//
//  SerializationError.swift
//  Retrolux
//
//  Created by Bryan Henderson on 4/4/17.
//  Copyright © 2017 Bryan. All rights reserved.
//

import Foundation

public enum SerializationError: Error {
    case keyNotFound(property: Property, forClass: Any.Type)
    case propertyDoesNotSupportNullValues(property: Property, forClass: Any.Type)
    case typeMismatch(expected: PropertyType, got: Any.Type?, property: String, forClass: Any.Type)
    case expectedDictionaryRootButGotArrayRoot
    case expectedArrayRootButGotDictionaryRoot
}
