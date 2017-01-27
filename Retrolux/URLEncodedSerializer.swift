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
    
    public func supports(outbound: [Any]) -> Bool {
        if outbound.isEmpty {
            return false
        }
        
        return !outbound.contains(where: { $0 is Field == false && $0 is URLEncodedBody == false })
    }
    
    public func apply(arguments: [Any], to request: inout URLRequest) throws {
        var items: [URLQueryItem] = []
        for arg in arguments {
            if let body = arg as? URLEncodedBody {
                items.append(contentsOf: body.values.map { URLQueryItem(name: $0, value: $1) })
            } else if let field = arg as? Field {
                items.append(URLQueryItem(name: field.key, value: field.value))
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
