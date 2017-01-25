//
//  Path.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 10/9/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

public struct Path: SelfApplyingArg, MergeableArg, ExpressibleByStringLiteral {
    private let value: String
    private var mergeValue: String?
    
    public init(stringLiteral value: String) {
        self.value = value
    }
    
    public init(extendedGraphemeClusterLiteral value: String) {
        self.value = value
    }
    
    public init(unicodeScalarLiteral value: String) {
        self.value = value
    }
    
    public init(_ value: String) {
        self.value = value
    }
    
    public mutating func merge(with alignedArg: Any) {
        self.mergeValue = (alignedArg as! Path).value
    }
    
    public func apply(to request: inout URLRequest) {
        // TODO: Don't replace escaped variant. There has to be a better way...
        let token = "%7B" + mergeValue! + "%7D"
        request.url = URL(string: request.url!.absoluteString.replacingOccurrences(of: token, with: value))!
    }
}
