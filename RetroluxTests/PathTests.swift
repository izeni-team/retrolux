//
//  PathTests.swift
//  RetroluxTests
//
//  Created by Christopher Bryan Henderson on 8/24/17.
//  Copyright © 2017 Christopher Bryan Henderson. All rights reserved.
//

import XCTest
import Retrolux

class PathTests: XCTestCase {
    func testNoArgs() {
        let builder = makeTestBuilder()
        var request = builder.make(.get("users/{id}/"), response: Void.self)
        let url = builder.base.appendingPathComponent("users/{id}/")
        XCTAssert(request.data.url == url)
        let response = request.test(ResponseData(body: nil, status: nil, headers: nil, error: nil))
        XCTAssert(response.request.url == url)
    }
    
    func testSinglePath() {
        let builder = makeTestBuilder(base: URL(string: "https://example.com/")!)
        var request = builder.make(.get("users/{id}/"), args: Path("id"), response: Void.self)
        let url = URL(string: "https://example.com/")!.appendingPathComponent("users/{id}/")
        XCTAssert(request.data.url == url)
        let response = request.test(Path("woot"), simulated: ResponseData(body: nil, status: nil, headers: nil, error: nil))
        XCTAssert(response.request.url == URL(string: "https://example.com/users/woot/")!)
    }
    
    func testThreePaths() {
        let builder = makeTestBuilder()
        let request = builder.make(.get("users/{3}/{1}/{2}/"), args: (Path("1"), Path("2"), Path("3")), response: Void.self)
        let url = builder.base.appendingPathComponent("users/{3}/{1}/{2}/")
        XCTAssert(request.data.url == url)
        let response = request.test((Path("one"), Path("two"), Path("three")), simulated: ResponseData(body: nil, status: nil, headers: nil, error: nil))
        XCTAssert(response.request.url == builder.base.appendingPathComponent("users/three/one/two/"))
    }
    
    func testUsingPathForQuery() {
        let builder = makeTestBuilder()
        var request = builder.make(.get("users/?id={id}"), args: Path("id"), response: Void.self)
        let url = builder.base.appendingPathComponent("users/?id={id}")
        XCTAssert(request.data.url == url)
        let response = request.test(Path("id"), simulated: ResponseData(body: nil, status: nil, headers: nil, error: nil))
        XCTAssert(response.request.url == builder.base.appendingPathComponent("users/?id=id"))
    }
}
