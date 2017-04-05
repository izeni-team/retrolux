//
//  PathTests.swift
//  Retrolux
//
//  Created by Bryan Henderson on 1/26/17.
//  Copyright © 2017 Bryan. All rights reserved.
//

import Foundation
import XCTest
import Retrolux

class PathTests: XCTestCase {
    func testSinglePath() {
        let request = Builder.dry().makeRequest(method: .get, endpoint: "whatever/{id}/", args: Path("id"), response: Void.self)
        let response = request(Path("some_id_thing")).perform()
        XCTAssert(response.request.url?.absoluteString.hasSuffix("whatever/some_id_thing/") == true)
    }
    
    func testMultiplePaths() {
        let request = Builder.dry().makeRequest(method: .get, endpoint: "whatever/{id}/{id2}/", args: (Path("id"), Path("id2")), response: Void.self)
        let response = request((Path("some_id_thing"), Path("another_id_thing"))).perform()
        XCTAssert(response.request.url?.absoluteString.hasSuffix("whatever/some_id_thing/another_id_thing/") == true)
    }
    
    func testStringLiteralConversion() {
        let request = Builder.dry().makeRequest(method: .get, endpoint: "whatever/{id}/{id2}/", args: ("id" as Path, Path("id2")), response: Void.self)
        let response = request(("some_id_thing", "another_id_thing")).perform()
        XCTAssert(response.request.url?.absoluteString.hasSuffix("whatever/some_id_thing/another_id_thing/") == true)
    }
}
