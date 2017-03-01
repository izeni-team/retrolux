//
//  MultipartEncodeable.swift
//  Retrolux
//
//  Created by Bryan Henderson on 1/26/17.
//  Copyright © 2017 Bryan. All rights reserved.
//

import Foundation

public protocol MultipartEncodeable {
    static func encode(with arg: BuilderArg, using encoder: MultipartFormData)
}
