//
//  SwiftyJSONSerializer.swift
//  Retrolux
//
//  Created by Bryan Henderson on 4/4/17.
//  Copyright © 2017 Bryan. All rights reserved.
//

import Foundation
import Retrolux

enum SwiftyJSONSerializerError: Error {
    case invalidJSON
}

class SwiftyJSONSerializer: InboundSerializer, OutboundSerializer {
    func supports(inboundType: Any.Type) -> Bool {
        return inboundType is JSON.Type
    }
    
    func supports(outboundType: Any.Type) -> Bool {
        return outboundType is JSON.Type
    }
    
    func validate(outbound: [BuilderArg]) -> Bool {
        return outbound.count == 1 && outbound.first!.type is JSON.Type
    }
    
    func apply(arguments: [BuilderArg], to request: inout URLRequest) throws {
        let json = arguments.first!.starting as! JSON
        request.httpBody = try json.rawData()
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }
    
    func makeValue<T>(from clientResponse: ClientResponse, type: T.Type) throws -> T {
        let result = JSON(data: clientResponse.data ?? Data())
        if result.object is NSNull {
            throw SwiftyJSONSerializerError.invalidJSON
        }
        return result as! T
    }
}
