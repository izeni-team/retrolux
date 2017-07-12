//
//  URLTransformer.swift
//  Retrolux
//
//  Created by Bryan Henderson on 7/12/17.
//  Copyright © 2017 Bryan. All rights reserved.
//

import Foundation

open class URLTransformer: NestedTransformer {
    public typealias TypeOfProperty = URL
    public typealias TypeOfData = String
    
    public enum Error: Swift.Error {
        case invalidURL
    }
    
    public init() {
        
    }
    
    open func setter(_ dataValue: String, type: Any.Type) throws -> URL {
        guard let url = URL(string: dataValue) else {
            throw Error.invalidURL
        }
        return url
    }
    
    open func getter(_ propertyValue: URL) throws -> String {
        return propertyValue.absoluteString
    }
}
