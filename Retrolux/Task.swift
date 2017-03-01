//
//  HTTPTaskProtocol.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 7/15/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

public protocol Task {
    func resume()
    func cancel()
}
