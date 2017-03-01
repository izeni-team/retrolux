//
//  Body.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 10/9/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

public struct Body<T>: WrappedSerializerArg {
    public let value: Any?
    public var type: Any.Type {
        return T.self
    }
    
    public init() {
        self.value = nil
    }
    
    public init(_ value: T) {
        self.value = value
    }
}
