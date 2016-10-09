//
//  Header.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 10/8/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

struct Header: SelfApplyingArg {
    let key: String
    let value: String
    
    init() {
        self.key = ""
        self.value = ""
    }
    
    init(key: String, value: String) {
        self.key = key
        self.value = value
    }
    
    func apply(to request: inout URLRequest) {
        request.addValue(value, forHTTPHeaderField: key)
    }
}
