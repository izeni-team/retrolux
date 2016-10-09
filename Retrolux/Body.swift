//
//  Body.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 10/9/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

class Body<T>: BodyValues, BodyInitializers {
    var type: Any.Type {
        return T.self
    }
    
    fileprivate var _value: T?
    var value: Any {
        return _value!
    }
    
    required init() {
        
    }
    
    required init(_ value: T) {
        self._value = value
    }
}
