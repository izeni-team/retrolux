//
//  HeaderTests.swift
//  Retrolux
//
//  Created by Bryan Henderson on 1/27/17.
//  Copyright © 2017 Bryan. All rights reserved.
//

import Foundation
import XCTest
import Retrolux

class HeaderTests: XCTestCase {
    func testHeaders() {
        let request = Builder.dry().makeRequest(method: .get, endpoint: "", args: (Header("Content-Type"), Header("Custom3")), response: Void.self)
        let response = request((Header("test"), Header("test2"))).perform()
        XCTAssert(response.request.value(forHTTPHeaderField: "Content-Type") == "test")
        XCTAssert(response.request.value(forHTTPHeaderField: "Custom3") == "test2")
    }
}
