//
//  Query.swift
//  Retrolux
//
//  Created by Bryan Henderson on 1/26/17.
//  Copyright © 2017 Bryan. All rights reserved.
//

import Foundation

public struct Query: SelfApplyingArg {
    private let value: String
    
    public init(_ nameOrValue: String) {
        self.value = nameOrValue
    }
    
    public static func apply(arg: BuilderArg, to request: inout URLRequest) {
        if let creation = arg.creation as? Query, let starting = arg.starting as? Query {
            guard let url = request.url else {
                return
            }
            
            guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                return
            }
            
            let name = creation.value
            let value = starting.value
            
            var queryItems = components.queryItems ?? []
            queryItems.append(URLQueryItem(name: name, value: value))
            components.queryItems = queryItems
            
            if let newUrl = components.url {
                request.url = newUrl
            } else {
                print("Error: Failed to apply query `\(name)=\(value)`")
            }
        }
    }
}
