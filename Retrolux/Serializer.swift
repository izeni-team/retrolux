//
//  Serializer.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 10/8/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

protocol Serializer {
    func supports(type: Any.Type) -> Bool
    func serialize<T>(from clientResponse: ClientResponse) throws -> T
    func deserialize<T>(from value: T, modify request: inout URLRequest) throws
}
