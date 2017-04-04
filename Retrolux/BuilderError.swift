//
//  BuilderError.swift
//  Retrolux
//
//  Created by Bryan Henderson on 4/4/17.
//  Copyright © 2017 Bryan. All rights reserved.
//

import Foundation

public enum BuilderError: Error {
    case unsupportedArgument(BuilderArg)
    case tooManyMatchingSerializers(serializers: [OutboundSerializer], arguments: [BuilderArg])
    case validationError(serializer: Serializer, arguments: [BuilderArg])
    case serializationError(serializer: Serializer, error: Error, arguments: [BuilderArg])
}
