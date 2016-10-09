//
//  Path.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 10/9/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

struct Path: AlignedSelfApplyingArg, ExpressibleByStringLiteral {
    let value: String
    
    init(stringLiteral value: String) {
        self.value = value
    }
    
    init(extendedGraphemeClusterLiteral value: String) {
        self.value = value
    }
    
    init(unicodeScalarLiteral value: String) {
        self.value = value
    }
    
    init(_ value: String) {
        self.value = value
    }
    
    func apply(to request: inout URLRequest, with alignedArg: Any) {
        // TODO: Don't replace escaped variant. There has to be a better way...
        let token = "%7B" + (alignedArg as! Path).value + "%7D"
        request.url = URL(string: request.url!.absoluteString.replacingOccurrences(of: token, with: value))!
    }
}
