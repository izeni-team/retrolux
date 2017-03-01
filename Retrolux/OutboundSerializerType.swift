//
//  OutboundSerializerType.swift
//  Retrolux
//
//  Created by Bryan Henderson on 2/21/17.
//  Copyright © 2017 Bryan. All rights reserved.
//

import Foundation

public enum OutboundSerializerType {
    case auto
    case urlEncoded
    case multipart
    case json
    case custom(serializer: Any.Type)
    
    func isDesired(serializer: Any) -> Bool {
        switch self {
        case .auto:
            return true
        case .custom(serializer: let type):
            return type(of: serializer) == type
        case .json:
            return serializer is ReflectionJSONSerializer
        case .multipart:
            return serializer is MultipartFormDataSerializer
        case .urlEncoded:
            return serializer is URLEncodedSerializer
        }
    }
}
