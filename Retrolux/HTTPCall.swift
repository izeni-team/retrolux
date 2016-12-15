//
//  HTTPCall.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 10/8/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

class HTTPCall<T>: Call<T> {
    fileprivate var delegatedStart: (@escaping (Response<T>) -> Void) throws -> Void
    fileprivate var delegatedCancel: () -> Void
    
    init(start: @escaping (@escaping (Response<T>) -> Void) -> Void, cancel: @escaping () -> Void) {
        self.delegatedStart = start
        self.delegatedCancel = cancel
    }
    
    override func enqueue(callback: @escaping (Response<T>) -> Void) throws {
        try delegatedStart(callback)
    }
    
    override func cancel() {
        delegatedCancel()
    }
}
