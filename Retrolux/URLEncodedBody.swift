//
//  URLEncodedBody.swift
//  Retrolux
//
//  Created by Bryan Henderson on 1/2/17.
//  Copyright © 2017 Bryan. All rights reserved.
//

import Foundation

public struct URLEncodedBody {
    public let values: [(key: String, value: String)]
    
    public init() {
        values = []
    }
    
    public init(values: [(key: String, value: String)]) {
        self.values = values
    }
}
