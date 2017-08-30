//
//  TestCommon.swift
//  RetroluxTests
//
//  Created by Christopher Bryan Henderson on 8/28/17.
//  Copyright © 2017 Christopher Bryan Henderson. All rights reserved.
//

import Foundation
import Retrolux

fileprivate let testBuilderPath = "https://www.google.com/"

func makeTestBuilder(base: URL = URL(string: testBuilderPath)!) -> Builder {
    return Builder(base: base)
}

extension String {
    var utf8: Data {
        return self.data(using: .utf8)!
    }
}

extension Data {
    var utf8: String {
        return String(data: self, encoding: .utf8)!
    }
}
