//
//  Utils.swift
//  Retrolux
//
//  Created by Bryan Henderson on 2/28/17.
//  Copyright © 2017 Bryan. All rights reserved.
//

import UIKit
import Retrolux

struct Utils {
    static let testImage = UIImage(named: "something.jpg", in: Bundle(for: BuilderTests.self), compatibleWith: nil)!
}

extension Builder {
    static let dummy = dry
}
