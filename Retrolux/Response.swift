//
//  Response.swift
//  Retrolux
//
//  Created by Mitchell Tenney on 9/12/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

struct RLError {
    var rawResponse: Data?
}

struct RLResponse<T> {
    // Do we want the NSURLRequest or NSHTTPURLResponse?
    let request: URLRequest?
    let response: HTTPURLResponse?
    
    let rawResponse: Data?
    let result: RLResult<T>
    
    var error: RLError? {
        return result.error
    }
    
    var body: T? {
        switch result {
        case .success(let value):
            return value
        case .error(_):
            return nil
        }
    }
    
}

enum RLResult<T> {
    case success(value: T)
    case error(error: RLError)
    
    var error: RLError? {
        if case .error(let error) = self {
            return error
        }
        return nil
    }
}
