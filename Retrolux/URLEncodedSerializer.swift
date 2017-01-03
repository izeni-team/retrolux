//
//  URLEncodedSerializer.swift
//  Retrolux
//
//  Created by Bryan Henderson on 12/22/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

public class URLEncodedSerializer: Serializer {
    public init() {
        
    }
    
    public func supports(type: Any.Type, args: [Any], direction: SerializerDirection) -> Bool {
        return type is URLEncodedBody.Type && direction == .outbound
    }
    
    public func makeValue<T>(from clientResponse: ClientResponse, type: T.Type) throws -> T {
        fatalError("This serializer only supports outbound serialization.")
    }
    
    public func apply<T>(value: T, to request: inout URLRequest) throws {
        assert(value is URLEncodedBody)
        
        let body = value as! URLEncodedBody
        
        var components = URLComponents()
        components.queryItems = body.values.map { URLQueryItem(name: $0, value: $1) }
        let string = components.percentEncodedQuery
        print("string: \(string)")
        let data = string?.data(using: .utf8)
        request.httpBody = data
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    }
}
