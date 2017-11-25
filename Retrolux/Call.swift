//
//  Call.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 11/24/17.
//  Copyright © 2017 Christopher Bryan Henderson. All rights reserved.
//

import Foundation

class Call<T> {
    func enqueue(callback: @escaping (Response<T>) -> Void) {
        fatalError()
    }
    
    func perform() -> Response<T> {
        fatalError()
    }
    
    func cancel() {
        fatalError()
    }
}
