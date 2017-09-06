//
//  HeaderTests.swift
//  RetroluxTests
//
//  Created by Christopher Bryan Henderson on 8/28/17.
//  Copyright © 2017 Christopher Bryan Henderson. All rights reserved.
//

import Foundation
import XCTest
import Retrolux

class HeaderTests: XCTestCase {
    func testSingleHeader() {
        let builder = makeTestBuilder()
        let request = builder.make(
            .get(""),
            args: Header("Custom-Header"),
            response: Void.self
        )
        let response = request.test(Header("some-value"), simulated: .empty)
        XCTAssert(response.request.value(forHTTPHeaderField: "Custom-Header") == "some-value")
        XCTAssert(response.request.allHTTPHeaderFields?.count == 1)
    }
    
    func testThreeHeaders() {
        let builder = makeTestBuilder()
        let request = builder.make(.get(""), args: (Header("Custom-Header1"), Header("Custom-Header2"), Header("Custom-Header3")), response: Void.self)
        let response = request.test((Header("some-value1"), Header("some-value2"), Header("some-value3")), simulated: .empty)
        XCTAssert(response.request.value(forHTTPHeaderField: "Custom-Header1") == "some-value1")
        XCTAssert(response.request.value(forHTTPHeaderField: "Custom-Header2") == "some-value2")
        XCTAssert(response.request.value(forHTTPHeaderField: "Custom-Header3") == "some-value3")
        XCTAssert(response.request.allHTTPHeaderFields?.count == 3)
    }
    
    func testHeaderDictionary() {
        XCTFail()
    }
}
