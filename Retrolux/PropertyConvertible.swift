//
//  PropertyConvertible.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 7/12/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

public protocol PropertyConvertible {
    func set(value value: Any?, forProperty: Property) throws
    func valueFor(property: Property) -> Any?
}