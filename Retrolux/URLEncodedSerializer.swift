//
//  URLEncodedSerializer.swift
//  Retrolux
//
//  Created by Bryan Henderson on 12/22/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

fileprivate protocol URLEncodedSerializer_ArrayOrDictionary {}
extension Array: URLEncodedSerializer_ArrayOrDictionary {}
extension Dictionary: URLEncodedSerializer_ArrayOrDictionary {}

public class URLEncodedSerializer: Serializer {
    public func supports(type: Any.Type, args: [Any], direction: SerializerDirection) -> Bool {
        return type is URLEncodedSerializer_ArrayOrDictionary.Type && direction == .outbound
    }
    
    public func makeValue<T>(from clientResponse: ClientResponse, type: T.Type) throws -> T {
        fatalError("This serializer only supports outbound serialization.")
    }
    
    public func apply<T>(value: T, to request: inout URLRequest) throws {
        /*
         let connect = builder.makeRequest(
         "online/api/v2/app/login",
         args: Body<URLEncodedBody>(),
         response: Body<LoginResponse>()
         )
         
         let args = URLEncodedBody(keyAndValuePairs: [
         ("username", "utteacher"),
         ("password", "demo")
         ])
         connect(args).enqueue { response in
         
         }
         */
    }
}
