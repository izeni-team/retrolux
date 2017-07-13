//
//  ResponseError.swift
//  Retrolux
//
//  Created by Bryan Henderson on 4/4/17.
//  Copyright © 2017 Bryan. All rights reserved.
//

import Foundation

public enum ResponseError: RetroluxError {
    case invalidHttpStatusCode(code: Int?)
    case connectionError(Error)
    
    public var rl_error: RetroluxErrorDescription {
        switch self {
        case .invalidHttpStatusCode(code: let code):
            return RetroluxErrorDescription(
                description: code != nil ? "Unexpected HTTP status code, \(code!)." : "Expected an HTTP status code, but got no response.",
                suggestion: nil
            )
        case .connectionError(let error):
            return RetroluxErrorDescription(
                description: error.localizedDescription,
                suggestion: (error as NSError).localizedRecoverySuggestion ?? "Please check your Internet connection and try again."
            )
        }
    }
}
