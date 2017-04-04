//
//  ResponseError.swift
//  Retrolux
//
//  Created by Bryan Henderson on 4/4/17.
//  Copyright © 2017 Bryan. All rights reserved.
//

import Foundation

public enum ResponseError: Error {
    case invalidHttpStatusCode(code: Int?)
}
