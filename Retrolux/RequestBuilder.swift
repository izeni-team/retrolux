//
//  RequestBuilder.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 11/24/17.
//  Copyright © 2017 Christopher Bryan Henderson. All rights reserved.
//

import Foundation

class RequestBuilder {
    let base: URL
    var converters: [Converter] = []
    
    init(base: URL) {
        self.base = base
    }
    
    func get(_ endpoint: String, _ args: CustomStringConvertible...) -> Request {
        fatalError()
    }
    
    func post(_ endpoint: String, _ args: CustomStringConvertible...) -> Request {
        fatalError()
    }
}
