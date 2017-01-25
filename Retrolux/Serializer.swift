//
//  Serializer.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 10/8/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

public protocol Serializer {
    func supports(outbound: [Any]) -> Bool
    func supports(inboundType: Any.Type) -> Bool
    func makeValue<T>(from clientResponse: ClientResponse, type: T.Type) throws -> T
    func apply(arguments: [Any], to request: inout URLRequest) throws
}
