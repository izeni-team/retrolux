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
        let builder = RetroluxBuilder(baseURL: URL(string: "http://127.0.0.1/")!)
        let request = builder.makeRequest(method: .post, endpoint: "whatever/", args: Query("name"), response: Void.self)
        
        let expectation = self.expectation(description: "Waiting for response")
        
        request(Query("value")).enqueue { response in
            XCTAssert(response.request.url?.absoluteString.hasSuffix("whatever/?name=value") == true)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1) { (error) in
            if error != nil {
                XCTFail("Failed with error: \(error)")
            }
        }
    }
    
    func testMultipleQueries() {
        let builder = RetroluxBuilder(baseURL: URL(string: "http://127.0.0.1/")!)
        let request = builder.makeRequest(method: .get, endpoint: "whatever/", args: (Query("name"), Query("last")), response: Void.self)
        
        let expectation = self.expectation(description: "Waiting for response")
        
        request((Query("value"), Query("I wuv zis!="))).enqueue { response in
            XCTAssert(response.request.url?.absoluteString.hasSuffix("whatever/?name=value&last=I%20wuv%20zis!%3D") == true)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1) { (error) in
            if error != nil {
                XCTFail("Failed with error: \(error)")
            }
        }
    }
}
