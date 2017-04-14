//
//  PropertyConfig.swift
//  Retrolux
//
//  Created by Bryan Henderson on 4/14/17.
//  Copyright © 2017 Bryan. All rights reserved.
//

import Foundation

public enum PropertyConfigValidationError: RetroluxError {
    case cannotSetOptionsForNonExistantProperty(propertyName: String, forClass: Any.Type)
    case serializedNameAlreadyTaken(propertyName: String, alreadyTakenBy: String, serializedName: String, onClass: Any.Type)
    
    public var rl_error: RetroluxErrorDescription {
        switch self {
        case .cannotSetOptionsForNonExistantProperty(propertyName: let propertyName, forClass: let `class`):
            return RetroluxErrorDescription(
                description: "Cannot set options for non-existant property '\(propertyName)' on \(`class`).",
                suggestion: "Either fix name of the property '\(propertyName)' on \(`class`), or remove it from the config."
            )
        case .serializedNameAlreadyTaken(propertyName: let propertyName, alreadyTakenBy: let alreadyTakenBy, serializedName: let serializedName, onClass: let `class`):
            return RetroluxErrorDescription(
                description: "Cannot set serialized name of property '\(propertyName)' on \(`class`) to \"\(serializedName)\", because the property '\(alreadyTakenBy)' is already set to \"\(serializedName)\"!",
                suggestion: "Change the serialized name of either '\(propertyName)' or '\(alreadyTakenBy)' on \(`class`), or remove one of the properties."
            )
        }
    }
}

public class PropertyConfig {
    public enum Option {
        case ignored
        case nullable
        case serializedName(String)
        case transformed(TransformerType)
    }
    
    public var storage: [String: [Option]] = [:]
    public var validator: (PropertyConfig, String, [Option]) throws -> Void
    
    public init(validator: @escaping (PropertyConfig, String, [Option]) throws -> Void = { _ in }) {
        self.validator = validator
    }
    
    public subscript(name: String) -> [Option] {
        get {
            return storage[name] ?? []
        }
        set {
            do {
                try validator(self, name, newValue)
                storage[name] = newValue
            } catch {
                assert(false, error.localizedDescription)
            }
        }
    }
}
