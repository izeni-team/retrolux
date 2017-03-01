//
//  Header.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 10/8/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

public struct Header: SelfApplyingArg {
    private var value: String
    
    public init(_ nameOrValue: String) {
        self.value = nameOrValue
    }
    
    public static func apply(arg: BuilderArg, to request: inout URLRequest) {
        if let creation = arg.creation as? Header, let starting = arg.starting as? Header {
            request.addValue(starting.value, forHTTPHeaderField: creation.value)
        }
    }
}
