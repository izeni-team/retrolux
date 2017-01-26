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
    
    public func supports(outbound: [Any]) -> Bool {
        return !outbound.contains { $0 is MultipartEncodeable == false }
    }
    
    public func apply(arguments: [Any], to request: inout URLRequest) throws {
        let encoder = MultipartFormData()
        let encodeables = arguments.map { $0 as! MultipartEncodeable }
        for encodeable in encodeables {
            encodeable.encode(using: encoder)
        }
        request.httpBody = try encoder.encode()
        request.setValue(encoder.contentType, forHTTPHeaderField: "Content-Type")
        request.setValue("\(encoder.contentLength as UInt64)", forHTTPHeaderField: "Content-Length")
    }
}
