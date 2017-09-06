//
//  BuilderTests.swift
//  RetroluxTests
//
//  Created by Christopher Bryan Henderson on 8/24/17.
//  Copyright © 2017 Christopher Bryan Henderson. All rights reserved.
//

import Foundation
import XCTest
import Retrolux

class BuilderTests: XCTestCase {
    func testEmptyGetRequest() {
        let builder = makeTestBuilder()
        let request = builder.make(.get("whatever/"), response: Void.self)
        let response = request.test(.empty)
        XCTAssert(response.body != nil && response.body! == ())
        XCTAssert(response.error == nil)
        XCTAssert(response.headers == nil)
        XCTAssert(response.isSuccessful == false)
        XCTAssert(response.request.httpBody == nil)
        XCTAssert(response.request.allHTTPHeaderFields?.count == 0)
        XCTAssert(response.request.httpMethod == "GET")
        XCTAssert(response.request.httpBodyStream == nil)
        XCTAssert(response.request.url == builder.base.appendingPathComponent("whatever/"))
    }
    
    func testGetRoot() {
        let someRoot = URL(string: "https://some.root.url")!
        let builder = makeTestBuilder(base: someRoot)
        let request = builder.make(.get(""), response: Void.self)
        let response = request.test(.empty)
        XCTAssert(response.request.url == URL(string: "https://some.root.url/")!)
        XCTAssert(URL(string: "https://some.root.url")! != URL(string: "https://some.root.url/")!)
    }
    
    func testUnsupportedBodyType() {
        let builder = makeTestBuilder()
        let request = builder.make(.get(""), body: Int.self, response: Void.self)
//        let response = request.test(3, simulated: .empty)
        XCTFail()
    }
    
    func testUnsupportedArg() {
        let builder = makeTestBuilder()
        let request = builder.make(.get(""), args: 3, response: Void.self)
//        let response = request.test(3, simulated: .empty)
        XCTFail()
    }
}
