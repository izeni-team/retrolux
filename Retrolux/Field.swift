//
//  Field.swift
//  Retrolux
//
//  Created by Bryan Henderson on 1/27/17.
//  Copyright © 2017 Bryan. All rights reserved.
//

import Foundation

public struct Field: SerializerArg, MergeableArg, MultipartEncodeable {
    private var _keyOrValue: String
    private var _key: String?
    
    public var key: String {
        return _key!
    }
    
    public var value: String {
        assert(_key != nil)
        return _keyOrValue
    }
    
    public init(_ keyOrValue: String) {
        _keyOrValue = keyOrValue
    }
    
    public mutating func merge(with arg: Any) {
        _key = (arg as! Field)._keyOrValue
    }
    
    public func encode(using encoder: MultipartFormData) {
        encoder.append(value.data(using: .utf8)!, withName: key)
    }
}
