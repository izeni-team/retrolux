//
//  MergeableArg.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 10/9/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

public protocol MergeableArg {
    mutating func merge(with arg: Any)
}
