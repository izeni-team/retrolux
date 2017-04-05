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
    static func dummy() -> Builder {
        return Builder(base: URL(string: "https://e7c37c97-5483-4522-b400-106505fbf6ff.com/")!)
    }
}
