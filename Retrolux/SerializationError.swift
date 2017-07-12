//
//  ReflectorReflectorSerializationError.swift
//  Retrolux
//
//  Created by Bryan Henderson on 4/4/17.
//  Copyright © 2017 Bryan. All rights reserved.
//

import Foundation

public enum ReflectorSerializationError: RetroluxError {
    case keyNotFound(propertyName: String, key: String, forClass: Any.Type)
    case propertyDoesNotSupportNullValues(propertyName: String, forClass: Any.Type)
    case typeMismatch(expected: PropertyType, got: Any.Type?, propertyName: String, forClass: Any.Type)
    case expectedDictionaryRootButGotArrayRoot(type: Any.Type)
    case expectedArrayRootButGotDictionaryRoot(type: Any.Type)
    case invalidJSONData(Error)
    
    public var rl_error: RetroluxErrorDescription {
        switch self {
        case .keyNotFound(propertyName: let propertyName, key: let key, forClass: let `class`):
            return RetroluxErrorDescription(
                description: "Could not find the key '\(key)' in data for the property '\(propertyName)' on \(`class`).",
                suggestion: nil // TODO
            )
        case .propertyDoesNotSupportNullValues(propertyName: let propertyName, forClass: let `class`):
            return RetroluxErrorDescription(
                description: "The property '\(propertyName)' on \(`class`) does not support null.",
                suggestion: "Either make the property '\(propertyName)' on \(`class`) optional, or allow errors to be ignored."
            )
        case .typeMismatch(expected: let expected, got: let got, propertyName: let propertyName, forClass: let `class`):
            return RetroluxErrorDescription(
                description: "The property '\(propertyName)' on \(`class`) was given an incompatible value type, \(got). Expected type \(expected).", // TODO: Fix 'got'.
                suggestion: nil // TODO
            )
        case .expectedDictionaryRootButGotArrayRoot(type: let type):
            return RetroluxErrorDescription(
                description: "Wrong root type in JSON. Expected a dictionary, but got an array.",
                suggestion: "Either change your JSON root object to a dictionary, or change the expected type to an array, i.e. [\(type)].self instead of just \(type.self)."
            )
        case .expectedArrayRootButGotDictionaryRoot(type: let type):
            return RetroluxErrorDescription(
                description: "Wrong root type in JSON. Expected an array, but got a dictionary.",
                suggestion: "Either change your JSON root object to an array, or change the expected type to a dictionary, i.e. \(type.self) instead of [\(type)].self."
            )
        case .invalidJSONData(let error):
            return RetroluxErrorDescription(
                description: "The JSON data was invalid: \(error.localizedDescription)",
                suggestion: "Valid JSON is required. Check to see if the JSON is malformatted, or corrupt, or something other than JSON."
            )
        }
    }
}
