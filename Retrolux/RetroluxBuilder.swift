//
//  RetroluxBuilder.swift
//  Retrolux
//
//  Created by Bryan Henderson on 1/26/17.
//  Copyright © 2017 Bryan. All rights reserved.
//

import Foundation

public class RetroluxBuilder: Builder {
    public let baseURL: URL
    public let client: Client
    public let callFactory: CallFactory
    public var serializers: [Serializer]
    
    public init(baseURL: URL) {
        self.baseURL = baseURL
        self.client = HTTPClient()
        self.callFactory = HTTPCallFactory()
        self.serializers = [
            ReflectionJSONSerializer(),
            MultipartFormDataSerializer()
        ]
    }
}
