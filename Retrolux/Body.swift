//
//  Body.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 10/9/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

public struct Body<T>: WrappedSerializerArg {
    private var _value: T?
    public var value: Any {
        return _value!
    }
    
    public init() {
        
    }
    
    public init(_ value: T) {
        self._value = value
    }
}
