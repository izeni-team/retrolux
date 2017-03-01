//
//  Response.swift
//  Retrolux
//
//  Created by Mitchell Tenney on 9/12/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

public struct ErrorResponse {
    public let error: Error?
}

public struct Response<T> {
    // Do we want the NSURLRequest or NSHTTPURLResponse?
    public let request: URLRequest
    public let raw: ClientResponse?
    public let result: Result<T>
    
    public var body: T? {
        switch result {
        case .success(let value):
            return value
        case .failure:
            return nil
        }
    }
    
    public var isSuccessful: Bool {
        let status = raw?.status ?? 0
        switch result {
        case .success:
            return (200...299).contains(status)
        case .failure:
            return false
        }
    }
}

public enum Result<T> {
    case success(value: T)
    case failure(error: ErrorResponse)
    
    public var error: Error? {
        if case .failure(let error) = self {
            return error.error
        }
        return nil
    }
}
