//
//  BodyValues.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 10/9/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

public protocol BodyValues {
    var type: Any.Type { get }
    var value: Any { get }
}
