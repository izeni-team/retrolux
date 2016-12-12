//
//  Call.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 10/8/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

public class Call<T> {
    func enqueue(callback: @escaping (Response<T>) -> Void) throws {
        fatalError("Unimplemented. Should be overridden.")
    }
    
    func cancel() {
        fatalError("Unimplemented. Should be overridden.")
    }
}
