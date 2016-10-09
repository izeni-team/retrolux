//
//  BodyType.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 10/9/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

public protocol BodyInitializers: Arg {
    associatedtype T
    init(_ value: T)
}
