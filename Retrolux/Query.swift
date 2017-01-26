//
//  Query.swift
//  Retrolux
//
//  Created by Bryan Henderson on 1/26/17.
//  Copyright © 2017 Bryan. All rights reserved.
//

import Foundation

public struct Query: SelfApplyingArg, MergeableArg {
    private let value: String
    private var mergeValue: String?
    
    public init(_ value: String) {
        self.value = value
    }
    
    public mutating func merge(with arg: Any) {
        let query = arg as! Query
        self.mergeValue = query.value
    }
    
    public func apply(to request: inout URLRequest) {
        guard let url = request.url else {
            return
        }
        
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return
        }
        
        let name = mergeValue!
        let value = self.value
        
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
