//
//  WrappedSerializerArg.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 10/9/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

public protocol WrappedSerializerArg {
    var value: Any? { get }
    var type: Any.Type { get }
}
