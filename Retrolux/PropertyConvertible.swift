//
//  PropertyConvertible.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 7/12/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

public protocol PropertyConvertible {
    func properties() throws -> [Property]
    func set(value: Any?, for property: Property) throws
    func value(for property: Property) -> Any?
}
