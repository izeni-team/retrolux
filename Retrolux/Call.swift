//
//  Call.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 10/8/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

open class Call<T> {
    public init() {
        
    }
    
    open func test(callback: (Response<T>) -> Void) {
        fatalError("Unimplemented. Should be overridden.")
    }
    
    open func enqueue(callback: @escaping (Response<T>) -> Void) {
        fatalError("Unimplemented. Should be overridden.")
    }
    
    open func cancel() {
        fatalError("Unimplemented. Should be overridden.")
    }
}
