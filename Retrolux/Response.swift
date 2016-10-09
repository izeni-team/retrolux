//
//  Response.swift
//  Retrolux
//
//  Created by Mitchell Tenney on 9/12/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

struct ErrorResponse {
    var rawResponse: Data?
}

public struct Response<T> {
    // Do we want the NSURLRequest or NSHTTPURLResponse?
    let request: URLRequest?
    let response: HTTPURLResponse?
    
    let rawResponse: Data?
    let result: Result<T>
    
    var error: ErrorResponse? {
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

enum Result<T> {
    case success(value: T)
    case error(error: ErrorResponse)
    
    var error: ErrorResponse? {
        if case .error(let error) = self {
            return error
        }
        return nil
    }
}
