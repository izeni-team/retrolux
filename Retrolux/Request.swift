//
//  Request.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 11/24/17.
//  Copyright © 2017 Christopher Bryan Henderson. All rights reserved.
//

import Foundation

struct Request {
    struct Data {
        var method: String
        var url: URL
        var headers: [String: Any]
        var body: Any?
    }
    var data: Data
    
    init(method: String, url: URL) {
        self.data = Data(method: method, url: url, headers: [:], body: nil)
    }
    
    func build<T>() -> Call<T> {
        fatalError()
    }
    
    func query(_ key: String, _ value: CustomStringConvertible) -> Request {
        fatalError()
    }
    
    func queries(_ values: [String: CustomStringConvertible]) -> Request {
        fatalError()
    }
    
    func body(_ value: Any?) -> Request {
        fatalError()
    }
    
    var formUrlEncoded: Request {
        fatalError()
    }
    
    var multipart: Request {
        fatalError()
    }
    
    func header(_ key: String, _ value: String) -> Request {
        fatalError()
    }
    
    func headers(_ values: [String: CustomStringConvertible]) -> Request {
        fatalError()
    }
}
