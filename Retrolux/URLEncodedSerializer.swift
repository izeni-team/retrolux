//
//  URLEncodedSerializer.swift
//  Retrolux
//
//  Created by Bryan Henderson on 12/22/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

public class URLEncodedSerializer: OutboundSerializer {
    public init() {
        
    }
    
    public func supports(outboundType: Any.Type) -> Bool {
        return outboundType is Field.Type || outboundType is URLEncodedBody.Type
    }
    
    public func validate(outbound: [BuilderArg]) -> Bool {
        if outbound.isEmpty {
            return false
        }
        
        return !outbound.contains { !supports(outboundType: $0.type) }
    }
    
    public func apply(arguments: [BuilderArg], to request: inout URLRequest) throws {
        var items: [URLQueryItem] = []
        for arg in arguments {
            if let body = arg.starting as? URLEncodedBody {
                items.append(contentsOf: body.values.map { URLQueryItem(name: $0, value: $1) })
            } else if arg.type is Field.Type {
                if let creation = arg.creation as? Field, let starting = arg.starting as? Field {
                    items.append(URLQueryItem(name: creation.value, value: starting.value))
                }
            } else {
                fatalError("Unknown/unsupported type \(type(of: arg))")
            }
        }
        
        var components = URLComponents()
        components.queryItems = items
        let string = components.percentEncodedQuery
        let data = string?.data(using: .utf8)
        request.httpBody = data
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    }
}
