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
    func makeValue<T>(from clientResponse: ClientResponse, type: T.Type) throws -> T
    func apply<T>(value: T, to request: inout URLRequest) throws
}
