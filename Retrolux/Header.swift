//
//  Header.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 10/8/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

public struct Header: SelfApplyingArg, MergeableArg {
    private var value: String
    private var mergeValue: String?
    
    public init(_ nameOrValue: String) {
        self.value = nameOrValue
    }
    
    public mutating func merge(with arg: Any) {
        self.mergeValue = (arg as! Header).value
    }
    
    public func apply(to request: inout URLRequest) {
        request.addValue(value, forHTTPHeaderField: mergeValue!)
    }
}
