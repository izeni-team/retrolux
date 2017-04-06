//
//  Field.swift
//  Retrolux
//
//  Created by Bryan Henderson on 1/27/17.
//  Copyright © 2017 Bryan. All rights reserved.
//

import Foundation

public struct Field: MultipartEncodeable {
    public let value: String
    
    public init(_ keyOrValue: String) {
        self.value = keyOrValue
    }
    
    public static func encode(with arg: BuilderArg, using encoder: MultipartFormData) {
        if let creation = arg.creation as? Field, let starting = arg.starting as? Field {
            encoder.append(starting.value.data(using: .utf8)!, withName: creation.value)
        }
    }
}
