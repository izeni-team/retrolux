//
//  BuilderError.swift
//  Retrolux
//
//  Created by Bryan Henderson on 4/4/17.
//  Copyright © 2017 Bryan. All rights reserved.
//

import Foundation

public enum BuilderError: RetroluxError {
    case unsupportedArgument(BuilderArg)
    case serializerError(serializer: Serializer, error: Error, arguments: [BuilderArg])
    
    public var rl_error: RetroluxErrorDescription {
        switch self {
        case .unsupportedArgument(let arg):
            return RetroluxErrorDescription(
                description: "Unsupported argument type passed into builder: \(arg.type).",
                suggestion: "Either pass in a supported type, such as a Path, Query, Header, Body, or a serializer argument, or add a serializer that supports your argument type, \(arg.type)."
            )
        case .serializerError(serializer: let serializer, error: let error, arguments: _):
            return RetroluxErrorDescription(
                description: "The serialization error, \(error), was thrown by \(type(of: serializer)).",
                suggestion: "Check the serializer's documentation and/or source code to figure out why it doesn't like the argument(s) you passed into it."
            )
        }
    }
}
