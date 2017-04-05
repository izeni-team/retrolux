//
//  QueryTests.swift
//  Retrolux
//
//  Created by Bryan Henderson on 1/26/17.
//  Copyright © 2017 Bryan. All rights reserved.
//

import Foundation
import XCTest
import Retrolux

class QueryTests: XCTestCase {
    func testSingleQuery() {
        let request = Builder.dry().makeRequest(method: .post, endpoint: "whatever/", args: Query("name"), response: Void.self)
        let response = request(Query("value")).perform()
        XCTAssert(response.request.url?.absoluteString.hasSuffix("whatever/?name=value") == true)
    }
    
    func testMultipleQueries() {
        let request = Builder.dry().makeRequest(method: .get, endpoint: "whatever/", args: (Query("name"), Query("last")), response: Void.self)
        let response = request((Query("value"), Query("I wuv zis!="))).perform()
        XCTAssert(response.request.url?.absoluteString.hasSuffix("whatever/?name=value&last=I%20wuv%20zis!%3D") == true)
    }
}
