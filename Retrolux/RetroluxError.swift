//
//  RetroluxError.swift
//  Retrolux
//
//  Created by Bryan Henderson on 4/13/17.
//  Copyright © 2017 Bryan. All rights reserved.
//

import Foundation

public struct RetroluxErrorDescription {
    public let description: String
    public let suggestion: String?
    
    public init(description: String, suggestion: String?) {
        self.description = description
        self.suggestion = suggestion
    }
}

public protocol RetroluxError: LocalizedError, CustomStringConvertible, CustomDebugStringConvertible {
    var rl_error: RetroluxErrorDescription { get }
}

extension RetroluxError {
    public var description: String {
        let rl_error = self.rl_error
        if let suggestion = rl_error.suggestion {
            return "\(rl_error.description) \(suggestion)"
        }
        return rl_error.description
    }
    
    public var localizedDescription: String {
        return description
    }
    
    public var debugDescription: String {
        return description
    }
    
    public var errorDescription: String? {
        return rl_error.description
    }
    
    public var recoverySuggestion: String? {
        return rl_error.suggestion
    }
}
