//
//  Response.swift
//  Retrolux
//
//  Created by Mitchell Tenney on 9/12/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

struct ErrorResponse {
    let error: Error?
}

public struct Response<T> {
    // Do we want the NSURLRequest or NSHTTPURLResponse?
    let request: URLRequest
    let rawResponse: ClientResponse?
    let result: Result<T>
    
    var body: T? {
        switch result {
        case .success(let value):
            return value
        case .failure:
            return nil
        }
    }
    
    var isSuccessful: Bool {
        let status = rawResponse?.status ?? 0
        switch result {
        case .success:
            return (200...299).contains(status)
        case .failure:
            return false
        }
    }
}

enum Result<T> {
    case success(value: T)
    case failure(error: ErrorResponse)
    
    var error: Error? {
        if case .failure(let error) = self {
            return error.error
        }
        return nil
    }
}
