//
//  Path.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 10/9/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

public struct Path: SelfApplyingArg, ExpressibleByStringLiteral {
    public let value: String
    
    public init(stringLiteral value: String) {
        self.value = value
    }
    
    public init(extendedGraphemeClusterLiteral value: String) {
        self.value = value
    }
    
    public init(unicodeScalarLiteral value: String) {
        self.value = value
    }
    
    public init(_ value: String) {
        self.value = value
    }
    
    public static func apply(arg: BuilderArg, to request: inout URLRequest) {
        if let creation = arg.creation as? Path, let starting = arg.starting as? Path {
            // TODO: Don't replace escaped variant. There has to be a better way...
            let token = "%7B" + creation.value + "%7D"
            request.url = URL(string: request.url!.absoluteString.replacingOccurrences(of: token, with: starting.value))!
        }
    }
}
