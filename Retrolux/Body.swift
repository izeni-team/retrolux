//
//  Body.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 10/9/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

struct Body<T>: BodyValues {
    var type: Any.Type {
        return T.self
    }
    
    fileprivate var _value: T?
    var value: Any {
        return _value!
    }
    
    init() {
        
    }
    
    init(_ value: T) {
        self._value = value
    }
}
