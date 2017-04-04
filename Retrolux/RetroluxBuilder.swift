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
    public var requestInterceptor: ((inout URLRequest) -> Void)?
    public var responseInterceptor: ((inout ClientResponse) -> Void)?
    
    public init(baseURL: URL) {
        self.baseURL = baseURL
        self.client = HTTPClient()
        self.callFactory = HTTPCallFactory()
        self.serializers = [
            ReflectionJSONSerializer(),
            MultipartFormDataSerializer(),
            URLEncodedSerializer()
        ]
    }
    
    public func log(request: URLRequest) {
        print("Retrolux: \(request.httpMethod!) \(request.url!.absoluteString.removingPercentEncoding!)")
    }
    
    public func log<T>(response: Response<T>) {
        let status = response.status ?? 0
        
        if response.error is BuilderError == false {
            let requestURL = response.request.url!.absoluteString.removingPercentEncoding!
            print("Retrolux: \(status) \(requestURL)")
        }
        
        if let error = response.error {
            print("Retrolux: Error: \(error)")
        }
    }
}
