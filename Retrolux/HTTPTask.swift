//
//  HTTPTask.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 10/8/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

struct HTTPTask: Task {
    let task: URLSessionTask
    
    func resume() {
        task.resume()
    }
    
    func cancel() {
        task.cancel()
    }
}
