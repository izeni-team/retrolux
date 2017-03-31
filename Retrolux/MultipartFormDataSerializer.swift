//
//  MultipartFormDataSerializer.swift
//  Retrolux
//
//  Created by Bryan Henderson on 1/26/17.
//  Copyright © 2017 Bryan. All rights reserved.
//

import Foundation

public class MultipartFormDataSerializer: OutboundSerializer {
    public init() {
        
    }
    
    public func supports(outboundType: Any.Type) -> Bool {
        return outboundType is MultipartEncodeable.Type
    }
    
    public func validate(outbound: [BuilderArg]) -> Bool {
        return !outbound.contains { !supports(outboundType: $0.type) }
    }
    
    public func apply(arguments: [BuilderArg], to request: inout URLRequest) throws {
        let encoder = MultipartFormData()
        
        for arg in arguments {
            if let encodeableType = arg.type as? MultipartEncodeable.Type {
                encodeableType.encode(with: arg, using: encoder)
            }
        }
        
        let data = try encoder.encode()
        if data.count > 0 {
            request.httpBody = data
            request.setValue(encoder.contentType, forHTTPHeaderField: "Content-Type")
            request.setValue("\(encoder.contentLength as UInt64)", forHTTPHeaderField: "Content-Length")
        }
    }
}
