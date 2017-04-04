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
        let builder = RetroluxBuilder(baseURL: URL(string: "http://127.0.0.1/")!)
        let request = builder.makeRequest(method: .get, endpoint: "", args: (Header("Content-Type"), Header("Custom3")), response: Void.self)
        let expectation = self.expectation(description: "Waiting for request")
        request((Header("test"), Header("test2"))).enqueue { response in
            XCTAssert(response.request.value(forHTTPHeaderField: "Content-Type") == "test")
            XCTAssert(response.request.value(forHTTPHeaderField: "Custom3") == "test2")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1) { (error) in
            if let error = error {
                XCTFail("Failed with error: \(error)")
            }
        }
    }
}
